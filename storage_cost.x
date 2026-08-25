%#include "types.hh"

namespace hogd {

struct StorageCostModelXdr {
  ExtensionPoint ext;
  unsigned hyper base_data_item_cost;
  unsigned int bytestring_cost_per_byte;
  unsigned hyper base_contract_deployment_cost;
  unsigned hyper contract_deployment_cost_per_byte;
  unsigned hyper auth_per_key_cost;
  unsigned hyper rcq_cost_per_entry;
  unsigned hyper replay_cache_cost_per_entry;
  unsigned hyper balance_cost;
};

/// The network configuration committed to by ProposalHeader::config_hash.
/// New consensus-critical configuration belongs in this preimage.
struct ConfigHashPreimage {
  StorageCostModelXdr storage_cost_model;
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
