namespace hogd {

typedef opaque ValidatorID[32];

typedef Ed25519PublicKey ValidatorPublicKey;
typedef Ed25519SecretKey ValidatorSecretKey;

struct ValidatorPublicInfo {
  ValidatorPublicKey public_key;
  ServerAddress address;
};

struct ValidatorPrivateInfo {
  ValidatorPublicInfo public_info;
  ValidatorSecretKey secret_key;
};

struct QuorumSet {
  unsigned int threshold;
  ValidatorID validators<>;
  QuorumSet inner_sets<>;
};

struct QuorumSetSnapshot {
  Timestamp timestamp;
  QuorumSet quorum_set;
};

struct SignedQuorumSetSnapshot {
  ValidatorPublicInfo validator_public_info;
  QuorumSetSnapshot quorum_set_snapshot;
  Signature validator_signature;
};

typedef SignedQuorumSetSnapshot SignedQuorumSetSnapshots<>;

struct KnownQuorumSets {
  SignedQuorumSetSnapshots signed_quorum_set_snapshots;
  ValidatorPublicInfo validators<>;
};

program Discovery {
  version Discovery1 {

    void discovery_null(void) = 0;

    KnownQuorumSets discovery_update_quorums(KnownQuorumSets) = 10;
  }
  = 1;
}
= 0x3eef0505;

} // namespace hogd
