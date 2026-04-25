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

struct ValidatorSystemConfig {
  unsigned int base_private_port;
  unsigned int coordinator_public_port;
  //
  unsigned int exec_num_threads;
  unsigned hyper db_ram_bytes;
};

struct LoadgenSystemConfig {
  ValidatorSystemConfig validator_config;
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

struct VariantPlan {
  UnitDef unit_defs<>;
  SocketAddress public_address;
};

} // namespace hogx
