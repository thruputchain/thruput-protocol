// clang-format off
namespace hogx {
// clang-format on

// -- host def

typedef string HostID<>;

struct HostDef {
  HostID host_id;
  Tag host_tags<>;
  //
  string ssh_user<>;
  string ssh_address<>;
  unsigned int *ssh_port;
  string ssh_private_key<>;
  //
  HostConfig host_config;
};

// -- system definition and layouts

// SystemPorts specifies service ports.
struct SystemPorts {
  // coordinator
  unsigned int coordinator_public_port;
  unsigned int coordinator_public_wallet_port;
  unsigned int coordinator_private_port;
  unsigned int coordinator_private_metrics_port;
  unsigned int coordinator_scpd_local_port;
  unsigned int scpd_coordinator_local_port;
  // mempool
  unsigned int mempool_coordinator_private_port;
  unsigned int mempool_exec_private_port;
  unsigned int mempool_db_private_port;
  unsigned int mempool_event_private_port;
  unsigned int mempool_auth_private_port;
  // exec
  unsigned int exec_mempool_private_port;
  // db
  unsigned int db_exec_private_port;
  unsigned int db_mempool_private_port;
  unsigned int db_auth_private_port;
  // event
  unsigned int event_mempool_private_port;
  unsigned int event_exec_private_port;
  unsigned int event_indexer_private_port;
  // auth
  unsigned int auth_db_private_port;
  unsigned int auth_mempool_private_port;
  // indexer
  unsigned int indexer_event_private_port;
  unsigned int indexer_explorer_private_port;
};

struct ValidatorSystemConfig {
  SystemPorts ports;
  unsigned int exec_num_threads;
  unsigned hyper db_ram_bytes;
};

struct LoadgenSystemConfig {
  ValidatorSystemConfig validator_config;
  //
  unsigned int coordinator_private_debug_port;
  unsigned int loadgen_private_port;
  //
  unsigned hyper num_accounts;
  unsigned hyper txs_per_block;
  unsigned hyper num_blocks;
};

union SystemConfig switch (SystemType system_type) {
case SYSTEM_VALIDATOR:
  ValidatorSystemConfig validator_config;
case SYSTEM_LOADGEN:
  LoadgenSystemConfig loadgen_config;
};

// LayoutUnit maps (unit_type, unit_shard) to a host.
struct LayoutUnit {
  UnitRole unit_role;
  HostID host_id;
};

typedef LayoutUnit SystemLayout<>;

typedef string AssemblyID<>;

struct AssemblyDef {
  AssemblyID id;
  SystemConfig config;
  SystemLayout layout;
};

// -- cluster config

struct ClusterConfig {
  HostDef host_defs<>;
  AssemblyDef assembly_defs<>;
};

} // namespace hogx
