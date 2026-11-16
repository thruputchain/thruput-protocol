%#include "network.hh"
%#include "scp.hh"
%#include "types.hh"
%#include "validator.hh"

namespace hogd {

struct BristleconeQuorumSetSnapshot {
  TimePoint timestamp;
  BristleconeQuorumSet quorum_set;
};

struct BristleconeSignedQuorumSetSnapshot {
  ValidatorPublicInfo signer;
  Signature signature;
  BristleconeQuorumSetSnapshot quorum_set_snapshot;
};

struct BristleconeValidatorInfoSnapshot {
  TimePoint timestamp;
  ValidatorPublicInfo validator;
};

struct BristleconeSignedValidatorInfoSnapshot {
  ValidatorPublicInfo signer;
  Signature signature;
  BristleconeValidatorInfoSnapshot validator_snapshot;
};

struct BristleconeKnownQuorumSets {
  BristleconeSignedQuorumSetSnapshot quorum_set_snapshots<>;
  BristleconeSignedValidatorInfoSnapshot validator_snapshots<>;
};

program Discovery
{
  version Discovery2
  {

    void discovery_null(void) = 0;

    BristleconeKnownQuorumSets discovery_update_quorums(BristleconeKnownQuorumSets) = 10;
  }
  = 2;
}
= 0x3eef0707;

} // namespace hogd
