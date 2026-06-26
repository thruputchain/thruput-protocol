// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusBasisHash; // #[rust(newtype)]

struct ConsensusBasis {
  TimePoint timestamp;
  Nomination nomination;
  Upgrade upgrades<6>;
  ConsensusBasisHash prev_cv_hash;
};

typedef ConsensusBasis *OptConsensusBasis;


struct ConsensusValueCue {
  ValidatorPublicInfo proposer;
  ConsensusBasisHash cv_hash;
  ConsensusBasisHash prev_cv_hash;
  BlockHeight block_height;
  BlockHash block_hash;
  BlockHash prev_block_hash;
};

} // namespace hogd
