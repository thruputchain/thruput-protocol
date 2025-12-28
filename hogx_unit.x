// clang-format off
namespace hogx {
// clang-format on

struct UnitID {
  string system_id<>;  // sets HOGX_SYSTEM_ID; identifies a set of unit instances comprising a system deployment
  string unit_type<>;  // sets HOGX_UNIT_TYPE; e.g. `coordinator`, `mempool`, `exec`, `db`, `event`
  string unit_shard<>;  // sets HOGX_UNIT_SHARD
};

struct UnitBuild {
  string pkg<>;  // sets HOGX_PKG
};

struct UnitAgreement {
  StringMap meta<>;  // can use env variables
  SocketAddressMap endpoint<>;  // can use env variables; e.g. {"public-metrics": 178.10.0.3:2222}
};

struct Command {
  Path binary;  // can use env variables
  Flag flag<>;  // can use env variables
  StringMap env<>; // can use env variables
};

struct UnitDef {
  UnitID id;
  UnitBuild build;
  UnitAgreement agreement;
  Command cmd;
};

struct ProcessState {
  hyper pid;
  hyper age;
};

struct UnitState {
  UnitDef unit_def;
  Timestamp started;
  Timestamp *stopped;
  ProcessState process_state<>;  // unit and its child processes
  Path stdout;
  Path stderr;
};

} // namespace hogx
