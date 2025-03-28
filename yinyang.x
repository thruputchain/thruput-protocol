namespace hogd {

typedef opaque ValidatorID[16];

typedef Ed25519PublicKey ValidatorPublicKey;

typedef Ed25519Signature ValidatorSignature;

struct ValidatorCard {
	ValidatorID validator_id;
	ValidatorPublicKey validator_pubkey;
	ServerAddress validator_address;
};

typedef ValidatorCard QuorumSlice<>;

struct QuorumSlicesSnapshot {
  unsigned int block_height;
  QuorumSlice quorum_slices<>;
};

struct ValidatorQuorumSlicesSnapshot {
  ValidatorCard validator_card;
  QuorumSlicesSnapshot quorum_slices_snapshot;
  ValidatorSignature validator_signature; // over quorum_slices_snapshot
};

typedef ValidatorQuorumSlicesSnapshot ValidatorQuorumSlicesSnapshots<>;

program YinYang {
  version YinYang1 {

    void null(void) = 0;

    void update(ValidatorQuorumSlicesSnapshots) = 10;
  }
  = 1;
}
= 0x3eef0505;

} // namespace hogd
