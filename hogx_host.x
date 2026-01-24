// clang-format off
namespace hogx {
// clang-format on

struct HostConfig {
  string public_ip<>;  // HOGX_PUBLIC_IP
  string private_ip<>;  // HOGX_PRIVATE_IP
  unsigned int agent_port;
  Path pkg_dir;  // HOGX_PKG_DIR
  Path app_dir;  // HOGX_APP_DIR; application lifetime: hog db, coordinator storage, event db
  Path var_dir;  // HOGX_VAR_DIR; host lifetime: configs, logs, core dumps
  Path tmp_dir;  // HOGX_TMP_DIR; process lifetime
};

struct HostState {
  HostConfig config;
};

} // namespace hogx
