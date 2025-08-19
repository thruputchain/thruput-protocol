// clang-format off
%#include "types.hh"
%#include "transaction.hh"

namespace hogd {
  // clang-format on

  struct InitializationArgs {
    ContractEntrypointID entrypoint;
    Calldata calldata;
  };

  struct PresetDeploymentConfig {
    SHA256Hash initial_nonce;
    SHA256Hash contract_hash;
    InitializationArgs *initialization_args;
  };

  struct InitialConfigurationEntry {
    PresetDeploymentConfig config;
    int128_xdr amount;
  };

  typedef InitialConfigurationEntry InitialConfigurationList<>;

  struct GenesisBlock {
    InitialConfigurationList initial_config;
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
    kAddressInitialTokenClaim = 2,
  };

} // namespace hogd
