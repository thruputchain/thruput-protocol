// clang-format off
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]

// The XDR encoding of this structure is the value that the consensus protocol agrees upon.
struct ConsensusValue {
  ExtensionPoint ext;
  ValidatorID proposer;
  Upgrade upgrades<6>;
  ProposalHeader proposal_header;
  ProposalHash proposal_hash;
  ConsensusValueHash prev_value_hash;
};

// This structure is disseminated via broadcast.
// It associates a consensus value with a proposal.
// The associated proposal is derivable from the basis.
struct ConsensusBasis {
  ConsensusValue value;
  ProposalTxs proposal_txs;
};

} // namespace hogd
