% #include "types.hh"
% #include "contract.hh"

namespace hogd
{

struct PublicKeyConfig {
  PublicKey key; // union multiplexing over signature scheme (ed25519,...)
  Weight max_weight;
};

// If we use the bitmap approach below, should be less than the width of
// the bitmap.
// This constant is intended to match the MAX_SIGNERS constant in the Stellar protocol,
// which is 20.  We add 1 to account for the primary key on a Stellar account.
const MAX_SIGNERS = 21; // #[rust(const=u32)]
// Could be 1; Slightly useful to have multiple for sponsored gas,
// i.e. separating sponsor ops vs contract owner management
const MAX_GAS_CONFIGS = 5; // #[rust(const=u32)]

struct GasPermissionConfig {
  GasAmount limit;
  BitMap accepted_keys;
  Weight required_weight;
};

struct NonceConfig {
  BitMap accepted_keys;
  Weight required_weight;
};

typedef PublicKeyConfig *PublicKeyConfigOpt;  // #[rust(newtype)]

struct AccountAuthData {
  PublicKeyConfigOpt public_keys[MAX_SIGNERS];
  GasPermissionConfig gas_permissions<MAX_GAS_CONFIGS>;
  NonceConfig nonce_config;
  // TODO(geoff): this can be removed once hogdb has a way to track this directly
  // on each db item.
  BlockHeight last_written_height;
};

struct DeployedContractHash {
  SHA256Hash hash;
  // This field is technically redundant, but allows us to compute (and
  // update) storage costs without (re)loading the entire contract from
  // storage
  unsigned int contract_size;
  // This field is used as an annotation hint in the executor, to determine which 
  // type of runtime to instantiate.
  // Again, is redundant with the stored contract, but allows us to avoid loading the
  // whole contract from storage.
  ContractType contract_type;
};

struct AddressMetadata {
  DeployedContractHash deployed_contract;
};

} // namespace hogd
