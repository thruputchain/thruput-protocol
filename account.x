% #include "types.hh"
% #include "contract.hh"

namespace hogd
{

struct PublicKeyConfig {
  PublicKey key; // union multiplexing over signature scheme (ed25519,...)
  Weight max_weight;
};

struct GasPermissionConfig {
  GasAmount limit;
  BitMap accepted_keys;
  Weight required_weight;
};

// If an address is initialized as a new address (via the hash of a public key).,
// we will interpret the missing auth data following these sensible defaults.
// we additionally interpret that initial key as key 0 with weight 1.
// TODO(geoff) and TODO(dobog): The initialization workflow (when upgrading an address from just a pk to a full contract)
// should explicitly set the auth data with these defaults (maybe optionally something else),
// so that the default is NOT to accidentally lock the address.

const kDefaultNewAddressRequiredWeight = 1;
const kDefaultNewAddressAcceptedKeys = 0xFFFFFFFF;
const kDefaultNewAddressKeyID = 0;

struct NonceConfig {
  BitMap accepted_keys;
  Weight required_weight;
};

typedef PublicKeyConfig *PublicKeyConfigOpt;  // #[rust(newtype)]

struct AccountAuthData {
  PublicKeyConfigOpt public_keys[kMaxSigners];
  GasPermissionConfig gas_permissions<kMaxGasConfigs>;
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
