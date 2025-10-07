% #include "types.hh"

namespace hogd
{

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

struct DeployedContractHash {
  SHA256Hash hash;
  // This field is technically redundant, but allows us to compute (and
  // update) storage costs without (re)loading the entire contract from
  // storage
  unsigned int contract_size;
};

struct AddressMetadata {
  DeployedContractHash deployed_contract;
};

} // namespace hogd
