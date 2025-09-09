// clang-format off
% #include "types.hh"

namespace hogd
{
  // clang-format on

  struct PublicKeyConfig {
    bool valid;
    PublicKey key; // union multiplexing over signature scheme (ed25519,...)
    Weight max_weight;
  };

  // arbitary, small limit;
  // but if we use the bitmap approach below, should be less than the width of
  // the bitmap
  const MAX_SIGNERS = 20;
  // Could be 1; Slightly useful to have multiple for sponsored gas,
  // i.e. separating sponsor ops vs contract owner management
  const MAX_GAS_CONFIGS = 5;

  struct GasPermissionConfig {
    GasAmount limit;
    BitMap accepted_keys;
    Weight required_weight;
  };

  struct NonceConfig {
    BitMap accepted_keys;
    Weight required_weight;
  };

  struct AccountAuthData {
    PublicKeyConfig public_keys[MAX_SIGNERS];
    GasPermissionConfig gas_permissions<MAX_GAS_CONFIGS>;
    NonceConfig nonce_config;
  };

} // namespace hogd
