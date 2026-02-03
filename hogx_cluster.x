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
  unsigned int coordinator_public_validator_port;
  unsigned int coordinator_private_wallet_port;
  unsigned int coordinator_private_scheduler_port;
  unsigned int coordinator_private_metrics_port;
  unsigned int coordinator_scpd_local_port;
  unsigned int scpd_coordinator_local_port;
  // mempool
  unsigned int mempool_coordinator_private_port;
  unsigned int mempool_exec_private_port;
  unsigned int mempool_db_private_port;
  unsigned int mempool_event_private_port;
  // exec
  unsigned int exec_mempool_private_port;
  unsigned int exec_db_private_port;
  // db
  unsigned int db_exec_private_port;
  // event
  unsigned int event_mempool_private_port;
  unsigned int event_exec_private_port;
};

// LayoutDef maps all system units to cluster hosts.
struct LayoutDef {
  string layout_id<>;
  LayoutUnit layout_units<>;
  LayoutPorts layout_ports;
};

// -- cluster config

struct ClusterConfig {
  HostDef host_defs<>;
  LayoutDef layout_defs<>;
};

} // namespace hogx
