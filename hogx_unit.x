// clang-format off
namespace hogx {
// clang-format on

// input

enum SystemType {
  SYSTEM_VALIDATOR = 1,
  SYSTEM_LOADGEN = 2,
};

enum UnitType {
  // validator
  UNIT_COORDINATOR = 1,
  UNIT_MEMPOOL = 2,
  UNIT_EXEC = 3,
  UNIT_DB = 4,
  UNIT_EVENT = 5,
  UNIT_INDEXER = 6,
  // loadgen
  UNIT_LOADGEN = 100,
};

typedef string ChainID<>;

struct Context {
  AssemblyID assembly_id;
  ChainID chain_id;
  string uniquifier<>;
};

struct UnitRole {
  UnitType unit_type;
  string unit_shard<>;
};

struct UnitID {
  Context ctx;
  HostID host_id;
  UnitRole unit_role;
};

struct UnitBuild {
  string pkg<>;
};

struct UnitAgreement {
  StringMap meta;
  SocketAddressMap endpoint;
};

struct UnitCommand {
  Path binary_file;
  Path app_dir;  // for persistent application data; APP_ROOT/system_id/unit_type/unit_shard
  Path var_dir;  // for configs, logs and core dumps; VAR_ROOT/system_id/session_id/unit_type/unit_shard
  Path tmp_dir;  // for scratch; TMP_ROOT/system_id/session_id/unit_type/unit_shard
  Path stdout_file;  // var_dir/unit_type-unit_shard.stdout
  Path stderr_file;  // var_dir/unit_type-unit_shard.stderr
  Path combined_file;  // var_dir/unit_type-unit_shard.combined
  Flag flag<>;
  StringMap env;
  Files files;  // supporting files are placed in var_dir
};

struct UnitDef {
  UnitID id;
  UnitBuild build;
  UnitAgreement agreement;  // can use link variables
  UnitCommand command;  // can use link variables
};

enum ProcessStatus {
  PROCESS_RUNNING = 1,
  PROCESS_EXITED = 2,
  PROCESS_INTERRUPTED = 3,
};

union ProcessState switch (ProcessStatus status) {
case PROCESS_RUNNING:
  unsigned int pid;
case PROCESS_EXITED:
  int exit;
case PROCESS_INTERRUPTED:
  void;
};

struct UnitState {
  Timestamp time;
  UnitDef def;
  string user<>;
  Timestamp started;
  Timestamp *died;
  ProcessState process_state;
};

} // namespace hogx
