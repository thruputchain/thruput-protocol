%#include "types.hh"

namespace hogd {

//==============================================================================
// Contracts and Contract Deployment
//
// This module defines the contract abstraction in Groundhog. Contracts are
// code that can be deployed to addresses and invoked to execute logic.
//
// Key concepts:
// - Contracts can be WebAssembly blobs, native precompiled code, or test mocks
// - Contract addresses are deterministically derived from deployment parameters
// - Contract methods are identified by 8-byte entrypoint IDs
// - Entrypoint IDs are derived from interface names and versions
//==============================================================================

//------------------------------------------------------------------------------
// Contract Types and Code
//------------------------------------------------------------------------------

/// An opaque blob of WebAssembly code.
///
/// This is the raw WASM binary that will be executed by the Wasmi runtime.
struct ContractBlob {
  opaque wasm<>;
};

/// The execution environment for a contract.
enum ContractType {
  /// WebAssembly contract executed in the Wasmi runtime.
  ///
  /// This is the standard contract type for user-deployed contracts.
  kWasmi = 0,

  /// Precompiled native contract implemented directly in Rust.
  ///
  /// Used for system contracts like the native HogToken.
  /// More efficient than WASM but cannot be deployed by users.
  kNative = 1,

  /// Mock contract for local testing.
  ///
  /// Never deployed on-chain; exists only in the test harness.
  kMockTest = 2
};

/// A contract that can be deployed to an address and invoked.
///
/// Contracts are the fundamental unit of code execution in Groundhog.
/// Once deployed to a `ContractAddress`, they can be invoked by transactions
/// to execute their methods (entrypoints).
///
/// The three contract types serve different purposes:
/// - `kWasmi`: User-deployed contracts (most common)
/// - `kNative`: System contracts with privileged access
/// - `kMockTest`: Test contracts for local development
union Contract switch (ContractType contract_type)
{
case kWasmi:
  ContractBlob wasmi_contract;
case kNative:
  /// Identifier for which native contract this is.
  ///
  /// Native contracts are hard-coded in the runtime.
  int native_contract_id;
case kMockTest:
  /// Identifier for the mock contract in the test harness.
  int mock_contract_id;
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
/// This is Groundhog's analogue of Ethereum's `CREATE2` opcode, allowing
/// deterministic address derivation. The deployer controls the nonce to
/// create addresses at will.
///
/// # Example
///
/// ```text
/// Contract A address:  0x1234...
/// Contract B hash:     0xabcd...
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

  /// SHA-256 hash of the contract code being deployed.
  ///
  /// For WASM contracts, this is `SHA256(wasm_blob)`.
  /// For native contracts, this is a predefined hash.
  SHA256Hash contract_hash;
};

//------------------------------------------------------------------------------
// Contract Interfaces and Entrypoint Derivation
//------------------------------------------------------------------------------

/// Valid identifier string following RFC 4506.
///
/// Must be a letter followed by an optional sequence of letters, digits,
/// or underscores. Cannot be an XDR keyword (e.g., `"struct"`, `"union"`, `"enum"`).
///
/// # Examples
///
/// - `"transfer"`
/// - `"approve"`
/// - `"get_balance"`
typedef string Identifier<>;

/// Semantic version string following semver.org specification.
///
/// Format: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`
///
/// # Examples
///
/// - `"0.1.3"`
/// - `"1.0.0"`
/// - `"2.1.4-alpha"`
/// - `"1.0.0-alpha+001"`
typedef string SemVer<>;

/// Hash preimage for deriving contract interface identifiers.
///
/// Contract interfaces define a set of methods (entrypoints) with a name
/// and version. The first 6 bytes of `SHA256(ContractInterfaceIDPreimage)`
/// serve as a namespace prefix for all methods in that interface.
///
/// This allows:
/// - Interface versioning (same methods, different versions)
/// - Collision resistance (different interfaces, same method names)
/// - Stable method IDs across implementations
///
/// # Example
///
/// An interface `"ERC20"` version `"1.0.0"` will have a unique 6-byte
/// prefix, and all methods (`transfer`, `approve`, etc.) will share that prefix.
struct ContractInterfaceIDPreimage {
  /// Name of the contract interface.
  ///
  /// Should be descriptive and unique (e.g., `"ERC20"`, `"Governance"`, `"Oracle"`).
  Identifier name;

  /// Semantic version of the interface.
  ///
  /// Allows evolving interfaces while maintaining compatibility.
  SemVer vers;
};

/// 8-byte identifier for a contract method (entrypoint).
///
/// Entrypoint IDs uniquely identify which method to invoke on a contract.
/// They are computed as:
///
/// ```text
/// Bytes 0-5: SHA256(ContractInterfaceIDPreimage)[0..6]
/// Bytes 6-7: Method-specific ID chosen by interface author
/// ```
///
/// This two-level scheme provides:
/// 1. Interface-level namespace (6 bytes) - prevents collisions between interfaces
/// 2. Method-level identifier (2 bytes) - identifies specific method within interface
///
/// By default, the SDK lexicographically sorts method names and allocates the
/// last 2 bytes based on that order (first method gets 0x0000, second gets 0x0001, etc.).
///
/// # Example
///
/// For `"ERC20"` v1.0.0 interface:
///
/// ```text
/// SHA256("ERC20" || "1.0.0")[0..6] = 0xabcdef012345 (6-byte prefix)
///
/// Methods sorted lexicographically:
/// approve  -> method ID = 0x0000 -> Full entrypoint = 0xabcdef0123450000
/// transfer -> method ID = 0x0001 -> Full entrypoint = 0xabcdef0123450001
/// ```
typedef opaque ContractEntrypointID[8]; // #[rust(newtype)]

//------------------------------------------------------------------------------
// Deployed Contract Metadata
//------------------------------------------------------------------------------

/// Hash and metadata for a contract deployed at an address.
///
/// This allows the system to locate and instantiate the contract code
/// without loading the full contract from storage.
struct DeployedContractHash {
  /// SHA-256 hash of the deployed contract code.
  SHA256Hash hash;

  /// Size of the contract in bytes.
  ///
  /// Optimization: allows computing and updating storage costs without
  /// loading the full contract from storage.
  unsigned int contract_size;

  /// The type of contract (e.g., Wasm, native, etc.).
  ///
  /// Optimization: allows the executor to determine which runtime to
  /// instantiate without a database lookup. When the contract module is
  /// already cached, this avoids loading the contract bytecode entirely.
  ContractType contract_type;
};

/// Metadata associated with an address.
///
/// Currently only stores information about the deployed contract, if any.
/// This is the type stored at storage key `kStorageKeyTypeAddressMetadata`.
struct AddressMetadata {
  /// Information about the contract deployed at this address.
  DeployedContractHash deployed_contract;
};

} // namespace hogd

%#include "contract_format.h"
