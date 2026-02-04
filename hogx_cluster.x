// clang-format off
namespace hogx {
// clang-format on

// -- host def

struct HostDef {
  string host_id<>;
  Tag host_tags<>;
  //
  string ssh_user<>;
  string ssh_address<>;
  unsigned int *ssh_port;
  string ssh_private_key<>;
  //
  HostConfig host_config;
};

// -- system layouts

// LayoutUnit maps a unit_type:unit_shard to a cluster host.
struct LayoutUnit {
  UnitRole unit_role;
  string host_id<>;
};

// LayoutPorts specifies service ports.
struct LayoutPorts {
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
  // auth
  unsigned int auth_db_private_port;
  unsigned int auth_mempool_private_port;
};

// LayoutConfig provides services operational parameters.
struct LayoutConfig {
  unsigned int exec_num_threads;
  unsigned hyper db_ram_bytes;
};

// LayoutDef maps all system units to cluster hosts.
struct LayoutDef {
  string layout_id<>;
  SystemType system_type;
  LayoutUnit layout_units<>;
  LayoutPorts layout_ports;
  LayoutConfig layout_config;
};

// -- cluster config

struct ClusterConfig {
  HostDef host_defs<>;
  LayoutDef layout_defs<>;
};

} // namespace hogx
