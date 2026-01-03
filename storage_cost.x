%#include "types.hh"

namespace hogd {

struct StorageCostModelXdr {
  ExtensionPoint ext;
  int128_xdr base_data_item_cost;
  int bytestring_cost_per_byte;
  int128_xdr base_contract_deployment_cost;
  int128_xdr contract_deployment_cost_per_byte;
  int128_xdr auth_per_key_cost;
  int128_xdr replay_cache_cost_per_entry;
  int128_xdr balance_cost;
};

// Cost of storing a bytestring:
// base_data_item_cost + bytestring_cost_per_byte * bytestring_len

// Cost of storing a nonnegative int:
// base_data_item_cost

// Cost of deploying a contract:
// base_contract_deployment_cost + contract_deployment_cost_per_byte * contract_size

// cost of auth data:
// base_data_item_cost + auth_per_key_cost * num_keys

} // namespace hogd

