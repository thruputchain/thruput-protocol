// clang-format off
namespace hogx {
// clang-format on

// input

struct UnitID {
  string system_id<>;  // sets HOGX_UNIT_SYSTEM_ID; identifies a set of unit instances comprising a system deployment
  string unit_type<>;  // sets HOGX_UNIT_TYPE; e.g. `coordinator`, `mempool`, `exec`, `db`, `event`
  string unit_shard<>;  // sets HOGX_UNIT_SHARD
};

struct UnitBuild {
  string pkg<>;  // sets HOGX_UNIT_PKG
};

struct UnitAgreement {
  StringMap meta;  // can use link variables
  StringMap endpoint;  // can use link variables
};

struct UnitCommand {
  Path binary;  // can use link variables
  Flag flag<>;  // can use link variables
  StringMap env;  // can use link variables
};

struct UnitDef {
  UnitID id;
  UnitBuild build;
  UnitAgreement agreement;  // can use link variables
  UnitCommand command;  // can use link variables
};

// output: linked definitions

struct UnitAgreementLinked {
  StringMap meta;
  SocketAddressMap endpoint;
};

struct UnitCommandLinked {
  Path binary_file;
  Path app_dir;  // holds persistent application data; does not depend on system_id
  Path var_dir;  // holds log files and core dumps; mounted as /var; depends on system_id
  Path tmp_dir;  // mounted as /tmp; depends on system_id
  Path stdout_file;  // resides in var_dir
  Path stderr_file;  // resides in var_dir
  Flag flag<>;
  StringMap env;
};

struct UnitDefLinked {
  UnitID id;
  UnitBuild build;
  UnitAgreementLinked agreement;
  UnitCommandLinked command;
};

enum ProcessStatus {
  PROCESS_RUNNING = 1,
  PROCESS_EXITED = 2,
};

union ProcessState switch (ProcessStatus status) {
case PROCESS_RUNNING:
  unsigned int pid;
case PROCESS_EXITED:
  int exit;
};

struct UnitState {
  UnitDef def;
  UnitDefLinked def_linked;
  Timestamp started;
  ProcessState process_state;
};

} // namespace hogx
