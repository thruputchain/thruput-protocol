%#include "types.hh"

namespace hogd {

/// An opaque blob of WebAssembly code.
struct ContractBlob {
  opaque wasm<>;
};

enum ContractType {
  kWasmi = 0,
  kNative = 1,
  kMockTest = 2
};

/// A `Contract` is something that can be deployed and invoked onchain.
/// A contract can be deployed to a specific `ContractAddress`,
/// and then invoked at that address.
///
/// Groundhog currently supports three types of contracts:
/// - `kWasmi`: A contract that is implemented as a WASM blob.
/// - `kNative`: A contract that is implemented as a precompiled native contract.   
///   The primary example of a native contract is the one that implements the native token of the chain.
/// - `kMockTest`: A `kMockTest` contract is is never deployed on chain, 
///   but rather is created as part of the test harness when testing new contracts locally.
union Contract switch (ContractType contract_type)
{
case kWasmi:
  ContractBlob wasmi_contract;
case kNative:
  int native_contract_id;
case kMockTest:
  int mock_contract_id;
};

/// When one contract deploys another, the address of the resulting contract is the hash of this struct.
/// The nonce is an arbitrary value supplied by the calling contract.
/// Informally, this is the groundhog analogue of the Ethereum virtual machine's `CREATE2` opcode.
struct ContractDeploymentHashPreimage {
  ContractAddress deployer_address;
  SHA256Hash nonce;
  SHA256Hash contract_hash;
};

/// This type must be a valid "identifier" as defined in RFC 4506,
/// Section 6.2: "An identifier is a letter followed by an optional sequence
/// of letters, digits, or underbar ('_')."  It must also obey Section 6.4,
/// which lists keywords that may not be used as identifiers.
typedef string Identifier<>;

/// This type must be a valid version number as defined at
/// <https://semver.org/>.  For example, "0.1.3" or "1.0.0-alpha+001".
typedef string SemVer<>;

/// The hash of this type is used to compute the first 6 bytes of contract interface method IDs.
struct ContractInterfaceIDPreimage {
  Identifier name;
  SemVer vers;
};

/// This is an 8-byte opaque type that is computed as SHA256(ContractInterfaceIDPreimage)[0..6],
/// concatenated with a two-byte "method id" defined by the author of
/// the contract interface
typedef opaque ContractEntrypointID[8]; // #[rust(newtype)]

} // namespace hogd

%#include "contract_format.h"
