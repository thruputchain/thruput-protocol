%#include "precompiles.hh"
%#include "types.hh"

namespace hogd {

//==============================================================================
// Contracts and Contract Deployment
//
// This module defines the contract abstraction in Thruput. Contracts are
// code that can be deployed to addresses and invoked to execute logic.
//
// Key concepts:
// - Contracts can be executable blobs, native precompiled code, or test mocks
// - Contract addresses are deterministically derived from deployment parameters
// - Contract methods are identified by 8-byte entrypoint IDs
// - Entrypoint IDs are derived from interface names and versions
//==============================================================================

//------------------------------------------------------------------------------
// Contract Types and Code
//------------------------------------------------------------------------------

/// The largest contract code blob a chain admits when its configuration does
/// not state `kConfigParamMaxContractSizeBytes`. Includes the artifact header,
/// code, and initial memory.
const kDefaultMaxContractSizeBytes = 524288;

/// An opaque blob of executable code.
///
/// This is the raw binary that will be executed as an RV32 contract.
///
/// Unbounded on the wire: the size a chain admits is a configuration
/// parameter (`kConfigParamMaxContractSizeBytes`), enforced where a
/// transaction attaches a contract rather than where one is decoded.
struct ContractBlob {
  opaque data<>;
};

/// The execution environment for a contract.
///
/// Discriminant 0 is retired. It selected the Wasmi runtime, which was
/// removed once RV32 became the only deployable execution environment.
/// Do not reuse the value: old encodings that carry it must fail to parse
/// rather than silently decode as a live contract type.
enum ContractType {
  /// Precompiled native contract implemented natively by the node.
  ///
  /// Used for system contracts like the native token.
  /// Cheaper to invoke than a deployed RV32 contract, but users cannot
  /// deploy new ones.
  kNative = 1,

  /// Mock contract for local testing.
  ///
  /// Never deployed on-chain; exists only in the test harness.
  kMockTest = 2,

  /// RiscV contract executed in the RV32 VM.
  ///
  /// This is the standard contract type for user-deployed contracts.
  kRv32 = 3
};

/// A contract that can be deployed to an address and invoked.
///
/// Contracts are the fundamental unit of code execution in Thruput.
/// Once deployed to a `ContractAddress`, they can be invoked by transactions
/// to execute their methods (entrypoints).
///
/// The three contract types serve different purposes:
/// - `kRv32`: User-deployed contracts (most common)
/// - `kNative`: System contracts with privileged access
/// - `kMockTest`: Test contracts for local development
union Contract switch (ContractType contract_type)
{
case kNative:
  /// Identifier for which native contract this is.
  ///
  /// Native contracts are hard-coded in the runtime.
  HogexecPrecompiledNativeContracts native_contract_id;
case kMockTest:
  /// Identifier for the mock contract in the test harness.
  int mock_contract_id;
case kRv32:
  ContractBlob rv32_contract;
};

//------------------------------------------------------------------------------
// Contract Deployment and Address Derivation
//------------------------------------------------------------------------------

/// Hash preimage for deriving deployed contract addresses.
///
/// When a contract deploys another contract, the new contract's address is
/// deterministically computed as:
///
/// ```text
/// ContractAddress = SHA256(ContractDeploymentHashPreimage)
/// ```
///
/// Under XDR encoding, this struct serializes as the concatenation of its
/// fields: `deployer_address || nonce || contract_hash`.
///
/// This is Thruput's analogue of Ethereum's `CREATE2` opcode, allowing
/// deterministic address derivation. The deployer controls the nonce to
/// create addresses at will.
///
/// # Example
///
/// ```text
/// Contract A address:  0x1234...
/// Contract B hash:     0xabcd...   (= SHA256(XDR(Contract B)))
/// Deployment nonce:    0x5678...
/// Result: SHA256(0x1234... || 0x5678... || 0xabcd...) = Contract B address
/// ```
struct ContractDeploymentHashPreimage {
  /// The address of the contract performing the deployment.
  ContractAddress deployer_address;

  /// Arbitrary 32-byte value chosen by the deployer.
  ///
  /// Allows creating multiple instances of the same contract code
  /// at different addresses.
  SHA256Hash nonce;

  /// SHA-256 hash of the XDR-encoded `Contract` being deployed.
  ///
  /// This hashes the entire union, not the bare code blob:
  ///
  /// ```text
  /// contract_hash = SHA256(XDR(Contract))
  /// ```
  ///
  /// The encoding covers the 4-byte `ContractType` discriminant followed by
  /// the selected arm, so identical code deployed under a different contract
  /// type yields a different hash. For `kRv32` the arm is a `ContractBlob`,
  /// which is itself a 4-byte length prefix followed by the code padded to a
  /// 4-byte boundary -- hashing the raw code alone does not reproduce this
  /// value.
  ///
  /// Native and mock contracts are hashed the same way, over a union whose
  /// arm holds a contract identifier instead of a blob. They do not use
  /// separately predefined hash constants.
  SHA256Hash contract_hash;
};

//------------------------------------------------------------------------------
// Contract Interfaces and Entrypoint Derivation
//------------------------------------------------------------------------------

/// 8-byte identifier for a contract method (entrypoint).
///
/// Entrypoint IDs uniquely identify which method to invoke on a contract.
/// A contract may use any 8 bytes; the protocol attaches no meaning to them.
/// By default, the SDK derives them from the interface name, the major
/// version of the interface, and the method name:
///
/// ```text
/// SHA256(name || "::" || major || "::" || method)[0..8]
/// ```
///
/// `major` is the semver compatibility prefix of the interface version: the
/// leading components up to and including the first nonzero one (`"1"` for
/// `"1.4.2"`, `"0.2"` for `"0.2.7"`, `"0.0.3"` for `"0.0.3"`). Versions that
/// share it therefore share entrypoint IDs, and the `"::"` separators keep
/// distinct (name, major, method) triples from concatenating to the same
/// preimage.
///
/// # Example
///
/// For an `"ERC20"` interface at version `"1.0.0"`, `transfer` is
/// `SHA256("ERC20::1::transfer")[0..8]`.
///
/// Interface IDs use the same prefix under a domain tag,
/// `SHA256("thruput-interface::" || name || "::" || major)[0..8]`, so they
/// never coincide with an entrypoint ID.
typedef opaque ContractEntrypointID[8]; // #[rust(newtype)]

//------------------------------------------------------------------------------
// Deployed Contract Metadata
//------------------------------------------------------------------------------

/// Hash and metadata for a contract deployed at an address.
///
/// This allows the system to locate and instantiate the contract code
/// without loading the full contract from storage.
struct DeployedContractHash {
  /// SHA-256 hash of the XDR-encoded `Contract` deployed at this address.
  ///
  /// Computed as `SHA256(XDR(Contract))`, identically to the `contract_hash`
  /// field of `ContractDeploymentHashPreimage`.
  SHA256Hash hash;

  /// Size of the contract code in bytes.
  ///
  /// Always 0 for `kNative` and `kMockTest`, which carry no deployable blob.
  ///
  /// Optimization: allows computing and updating storage costs without
  /// loading the full contract from storage.
  unsigned int contract_size;

  /// The type of contract: RV32, native, or mock.
  ///
  /// Optimization: allows the executor to determine which runtime to
  /// instantiate without a database lookup. When the contract module is
  /// already cached, this avoids loading the contract bytecode entirely.
  ContractType contract_type;
};

} // namespace hogd

%#include "contract_format.h"
