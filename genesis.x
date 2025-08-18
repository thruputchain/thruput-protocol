// clang-format off
%#include "types.hh"

namespace hogd {
  // clang-format on

  struct PresetDeploymentConfig {
    SHA256Hash initial_nonce;
    SHA256Hash contract_hash;
    opaque initialize_calldata<>;
  };

  struct InitialConfigurationEntry {
    PresetDeploymentConfig config;
    int128_xdr amount;
  };

  typedef InitialConfigurationEntry InitialConfigurationList<>;

  struct GenesisBlock {
    InitialConfigurationList initial_config;
  };

} // namespace hogd
