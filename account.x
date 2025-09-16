// clang-format off
% #include "types.hh"

namespace hogd
{
  // clang-format on

  struct PublicKeyConfig {
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

  typedef PublicKeyConfig *PublicKeyConfigOpt;

  struct AccountAuthData {
    PublicKeyConfigOpt public_keys[MAX_SIGNERS];
    GasPermissionConfig gas_permissions<MAX_GAS_CONFIGS>;
    NonceConfig nonce_config;
  };

  // Each address maintains a map of [sha256(contract)] -> [ContractDeploymentRecord]
  struct ContractDeploymentRecord {
    // This is the number of times that the current address has deployed the contract 
    // AND where the current address is actively responsible for the reference to the contract
    // for those child addresses.
    //
    // This number increases by 1 when a contract is deployed, and decreases by 1
    // when a child address locks storage to support its own reference to the contract.
    unsigned int refcount;
  };

  struct SelfDeploymentMetadata {
    union switch (bool self_sponsored) {
      case true:
        void;
      case false:
        ContractAddress sponsor_address;
    } sponsor;
  };

  // Each address maintains a single AddressMetadata object.
  struct AddressMetadata {
    SHA256Hash deployed_contract;
    SelfDeploymentMetadata self_deployment_metadata;
  };

} // namespace hogd
