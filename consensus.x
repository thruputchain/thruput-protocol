// clang-format off
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]

struct ConsensusValue {
  ValidatorID proposer;
  Upgrade upgrades<6>;
  Synopsis synopsis;
  ProposalHash proposal_hash;
  ConsensusValueHash prev_value_hash;
};

struct ConsensusBasis {
  ConsensusValue value;
  Proposal proposal;
};

} // namespace hogd
