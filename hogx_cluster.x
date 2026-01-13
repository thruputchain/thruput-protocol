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

// LayoutDef maps all system units to cluster hosts.
struct LayoutDef {
  string layout_id<>;
  LayoutUnit layout_units<>;
};

// -- cluster config

struct ClusterConfig {
  HostDef host_defs<>;
  LayoutDef layout_defs<>;
};

} // namespace hogx
