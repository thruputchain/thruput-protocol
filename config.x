namespace hogd {

typedef hyper Milliseconds;
typedef hyper Seconds;

// ValidatorConfig holds the network configuration of a validator.
struct ValidatorConfig {
  ValidatorPrivateInfo private_info;
  ValidatorPublicInfo known_validators<>;
};

struct DiscoveryConfig {
  Milliseconds advertise_interval_msec;
  unsigned int advertise_par;
  Milliseconds snapshot_ttl_msec;
};

struct RouterConfig {
  unsigned int tree_fan_out;
};

struct DogwoodConfig {
  // navigator
  DogwoodInt32 route_count;
  Milliseconds route_time_to_live_msec;
  Milliseconds route_max_latency_msec;
  // endpoint caller
  DogwoodInt32 endpoint_max_pending;
  DogwoodInt32 endpoint_num_clients;
  Milliseconds endpoint_idle_ttl_msec;
  Milliseconds endpoint_dial_timeout_msec;
  Milliseconds endpoint_redial_delay_msec;
  Milliseconds endpoint_call_timeout_msec;
  // stream processing
  DogwoodInt32 stream_receiver_worker_count;
  DogwoodInt32 stream_sender_worker_count;
  // transmission processing
  DogwoodInt32 transmission_receiver_decode_worker_count;
  DogwoodInt32 transmission_sender_worker_count;
  //
  Milliseconds transmission_partial_max_ttl_msec;
  Milliseconds transmission_partial_idle_ttl_msec;
};

struct MempoolConfig {
  Milliseconds transaction_ttl_msec;
  hyper submission_lot_size;
  Milliseconds submission_lot_wait_msec;
};

struct CatchupConfig {
  Seconds catchup_block_ttl_sec;
  BlockHeight catchup_block_age;
};

struct BatonConfig {
  Milliseconds skew_msec;
  Milliseconds heartbeat_msec;
  Milliseconds patience_msec;
  int max_catchup_height;
};

struct RepairConfig {
  Milliseconds base_delay_msec;
  Milliseconds max_delay_msec;
  unsigned int multiplier_nom;
  unsigned int multiplier_denom;
};

struct StorageConfig {
  Milliseconds reclaim_interval_msec;
  int max_catchup_blocks;
  int max_scp_slots;
};

struct Config {
  ValidatorConfig *validator_config;
  DiscoveryConfig *discovery_config;
  RouterConfig *router_config;
  DogwoodConfig *dogwood_config;
  MempoolConfig *mempool_config;
  CatchupConfig *catchup_config;
  SCPConfig *scp_config;
  BatonConfig *baton_config;
  RepairConfig *repair_config;
  StorageConfig *storage_config;
};

/// The router of a coordinator's boundary, which chooses the dissemination
/// trees over the validators the boundary knows.
struct CoordinatorRouterConfig {
  /// The largest number of children of a node of a dissemination tree.
  unsigned hyper max_fanout;
};

/// The baton, which drives a coordinator's proposals and validations
/// through its scheduler.
struct CoordinatorBatonConfig {
  /// The expected maximum local clock skew between validators.
  Milliseconds clock_skew_msec;
};

/// The consensus protocol a coordinator's broker runs.
struct CoordinatorConsensusConfig {
  /// The number of slots in an epoch: the leader elected for an epoch
  /// proposes for all of its slots. Must be positive.
  unsigned hyper epoch_length;
  /// The pipeline width: how many slots ahead of the current slot the
  /// leader may propose. Must be positive.
  unsigned hyper pipeline_length;
  /// The time a slot is given to resolve before it is deemed late.
  Milliseconds timeout_msec;
};

/// The basis and block pools of a coordinator. Each keeps the values of
/// the latest heights in memory and evicts older ones to disk after a
/// commit.
struct CoordinatorPoolConfig {
  /// How many heights below the committed tip the basis pool keeps in
  /// memory.
  unsigned hyper basis_pool_hotcold_window;
  /// How many heights below the committed tip the block pool keeps in
  /// memory.
  unsigned hyper block_pool_hotcold_window;
};

/// The configuration of a coordinator: what its command line reads from
/// the file named by `coordinator start --config`.
struct CoordinatorConfig {
  CoordinatorRouterConfig router;
  DogwoodConfig dogwood;
  CoordinatorBatonConfig baton;
  CoordinatorConsensusConfig consensus;
  CoordinatorPoolConfig pool;
};

} // namespace hogd
