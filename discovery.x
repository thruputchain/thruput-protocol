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

typedef ValidatorPublicInfo QuorumSlice<>;

struct ValidatorQuorumSlicesSnapshot {
  ValidatorPublicInfo validator_public_info;
  QuorumSlice quorum_slices<>;
  Signature validator_signature; // over quorum_slices_snapshot
};

typedef ValidatorQuorumSlicesSnapshot ValidatorQuorumSlicesSnapshots<>;

program Discovery {
  version Discovery1 {

    void discovery_null(void) = 0;

    void discovery_update(ValidatorQuorumSlicesSnapshots) = 10;
  }
  = 1;
}
= 0x3eef0505;

} // namespace hogd
