%#include "network.hh"
%#include "scp.hh"
%#include "types.hh"
%#include "validator.hh"

namespace hogd {

struct QuorumSetSnapshot {
  TimePoint timestamp;
  SCPQuorumSet quorum_set;
};

struct SignedQuorumSetSnapshot {
  ValidatorPublicInfo signer;
  Signature signature;
  QuorumSetSnapshot quorum_set_snapshot;
};

struct ValidatorInfoSnapshot {
  TimePoint timestamp;
  ValidatorPublicInfo validator;
};

struct SignedValidatorInfoSnapshot {
  ValidatorPublicInfo signer;
  Signature signature;
  ValidatorInfoSnapshot validator_snapshot;
};

struct KnownQuorumSets {
  SignedQuorumSetSnapshot quorum_set_snapshots<>;
  SignedValidatorInfoSnapshot validator_snapshots<>;
};

program Discovery
{
  version Discovery1
  {

    void discovery_null(void) = 0;

    KnownQuorumSets discovery_update_quorums(KnownQuorumSets) = 10;
  }
  = 1;
}
= 0x3eef0505;

} // namespace hogd
