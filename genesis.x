// clang-format off
%#include "types.hh"
%#include "transaction.hh"
%#include "storage_cost.hh"
%#include "contract.hh"

namespace hogd {
// clang-format on

struct PresetDeploymentConfig {
  SHA256Hash initial_nonce;
  SHA256Hash contract_hash;
  ContractEntrypointID entrypoint;
  Calldata calldata;
};

struct InitialConfigurationEntry {
  PresetDeploymentConfig config;
  int128_xdr amount;
};

typedef InitialConfigurationEntry InitialConfigurationList<>;

struct GenesisConfiguration {
  InitialConfigurationList initial_config;
  StorageCostModelXdr storage_cost_model;

  /// The contract resolved for root invocations of undeployed addresses.
  /// Carried into the DbTip at genesis. GenesisConfigurationBuilder
  /// defaults this to the native default_wallet precompile's record.
  DeployedContractHash default_wallet;
};

/// Minimal genesis state for root-contract chain creation. Token allocation
/// happens through the root contract in the single ceremony block at height 1.
struct GenesisConfigurationV2 {
  NetworkHash network_hash;
  StorageCostModelXdr storage_cost_model;
  Contract root_contract;

  /// Preserved from V1 so the genesis transition does not implicitly alter
  /// undeployed-address invocation behavior.
  DeployedContractHash default_wallet;
};

// These translated into the contract addresses that are initialized
// at the start of the chain.
//
// The addresses (32 bytes) are all zeros, with the last 4 bytes equal
// to the enum value.
enum GenesisContractAddresses {
  // Null address (reserved)
  kAddressNull = 0,
  // Precompiled native contract for the HogToken contract
  kAddressPrecompiledHogToken = 1,
  // InitialTokenClaim contract, for managing genesis token/contract setup
  kAddressInitialTokenClaim = 2
};

} // namespace hogd
