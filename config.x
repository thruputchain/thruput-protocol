namespace hogd {

// Config holds the configuration of a validator.
struct Config {

  ValidatorPrivateInfo private_info;

  QuorumSlice quorum_slices<>;
};

} // namespace hogd
