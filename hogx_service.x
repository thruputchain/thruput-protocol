// clang-format off
namespace hogx {
// clang-format on

struct ServiceID {
  string system_id<>;  // sets HOGX_SYSTEM_ID; identifies a set of service instances comprising a system deployment
  string service_type<>;  // sets HOGX_SERVICE_TYPE; e.g. `coordinator`, `mempool`, `exec`, `db`, `event`
  string service_shard<>;  // sets HOGX_SERVICE_SHARD
};

struct ServiceBuild {
  string pkg<>;  // sets HOGX_PKG
};

struct ServiceAgreement {
  StringMap meta<>;  // can use env variables
  AddressMap endpoint<>;  // can use env variables; e.g. {"public-metrics": 178.10.0.3:2222}
};

struct Command {
  Path binary;  // can use env variables
  Flag flag<>;  // can use env variables
  StringMap env<>; // can use env variables
};

struct ServiceDef {
  ServiceID id;
  ServiceBuild build;
  ServiceAgreement agreement;
  Command cmd;
};

struct ProcessState {
  hyper pid;
  hyper age;
};

struct ServiceState {
  ServiceDef service_def;
  Timestamp started;
  Timestamp *stopped;
  ProcessState process_state<>;  // service and its child processes
  Path stdout;
  Path stderr;
};

} // namespace hogx
