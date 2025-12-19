// clang-format off
namespace hogx {
// clang-format on

struct HostDef {
  string id<>;
  Tag tag<>;
  string ssh_private_key<>;
  HostConfig host_config;
};

struct ClusterDef {
  string id<>;
  HostDef host_def<>;
};

} // namespace hogx
