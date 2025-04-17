namespace hogd {

// Config holds the configuration of a validator.
struct Config {
  ValidatorPrivateInfo private_info;
  QuorumSet quorum_set;
  ValidatorPublicInfo known_validators<>;
};

} // namespace hogd
