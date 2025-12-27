// clang-format off
namespace hogx {
// clang-format on

struct HostConfig {
  string public_ip<>;  // sets HOGX_PUBLIC_IP
  string private_ip<>;  // sets HOGX_PRIVATE_IP
  Path pkg_dir;  // sets HOGX_PKG_DIR
  Path app_dir;  // sets HOGX_APP_DIR; application lifetime: hog db, coordinator storage, event db
  Path var_dir;  // sets HOGX_VAR_DIR; host lifetime: configs, logs, core dumps
  Path tmp_dir;  // sets HOGX_TMP_DIR; process lifetime
};

struct HostState {
  HostConfig config;
};

} // namespace hogx
