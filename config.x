namespace hogd {

// ValidatorConfig holds the network configuration of a validator.
struct ValidatorConfig {
  ValidatorPrivateInfo private_info;
  QuorumSet quorum_set;
  ValidatorPublicInfo known_validators<>;
};

struct WalletConfig {
  WalletUser users<>;
};

struct BroadcastConfig {
  unsigned int multicast_tree_ttl_msec; // milliseconds
  hyper int chunk_size;
};

struct SpectraConfig {
  unsigned int num_data_channels;
  unsigned int num_parity_channels;
};

struct Config {
  ValidatorConfig *validator_config;
  WalletConfig *wallet_config;
  BroadcastConfig *broadcast_config;
  SpectraConfig *spectra_config;
};

} // namespace hogd
