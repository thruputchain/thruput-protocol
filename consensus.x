// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash;

struct ConsensusValue {
  TimePoint timestamp;
  Nomination nomination;
  Upgrade upgrades<6>;
  ConsensusValueHash prev_cv_hash;
};

typedef ConsensusValue *OptConsensusValue;


struct ConsensusValueCue {
  ValidatorPublicInfo proposer;
  ConsensusValueHash cv_hash;
  ConsensusValueHash prev_cv_hash;
  BlockHash block_hash;
  BlockHash prev_block_hash;
};

} // namespace hogd
