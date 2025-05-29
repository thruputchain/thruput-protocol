namespace hogd {

typedef hyper Milliseconds;
typedef hyper Seconds;

// ValidatorConfig holds the network configuration of a validator.
struct ValidatorConfig {
  ValidatorPrivateInfo private_info;
  QuorumSet quorum_set;
  ValidatorPublicInfo known_validators<>;
};

struct WalletConfig {
  JWTSecretKey secret_key;
  WalletUser users<>;
};

struct DiscoveryConfig {
  Milliseconds advertise_interval_msec;
  unsigned int advertise_par;
  Milliseconds snapshot_ttl_msec;
};

struct RouterConfig {
  unsigned int tree_fan_out;
};

struct BroadcastConfig {
  Milliseconds multicast_tree_ttl_msec; // milliseconds
  unsigned hyper chunk_size;
};

struct SpectraConfig {
  unsigned int num_payload_channels;
  unsigned int num_parity_channels;
  Milliseconds partial_ttl_msec;
};

struct MempoolConfig {
  Milliseconds proposed_batch_ttl_msec;
  Milliseconds transaction_ttl_msec;
  hyper submission_lot_size;
  Milliseconds submission_lot_wait;
};

struct CatchupConfig {
  Seconds catchup_block_ttl_sec;
  BlockHeight catchup_block_age;
};

struct BatonConfig {
  Milliseconds heartbeat_msec;
};

struct Config {
  ValidatorConfig *validator_config;
  WalletConfig *wallet_config;
  DiscoveryConfig *discovery_config;
  RouterConfig *router_config;
  BroadcastConfig *broadcast_config;
  SpectraConfig *spectra_config;
  MempoolConfig *mempool_config;
  CatchupConfig *catchup_config;
  SoloConfig *solo_config;
  BatonConfig *baton_config;
};

} // namespace hogd
