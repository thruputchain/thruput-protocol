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

struct Config {
  ValidatorConfig *validator_config;
  WalletConfig *wallet_config;
};

} // namespace hogd
