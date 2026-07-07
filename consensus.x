// clang-format off
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]

// The XDR encoding of this structure is the value that the consensus protocol agrees upon.
// Travels on network.
struct ConsensusValue {
  ExtensionPoint ext;
  ConsensusValueHash prev_value_hash;
  ProposalHeader proposal_header;
  ProposalTxsHash proposal_txs_hash;
  Upgrade upgrades<6>;
};

// This structure is disseminated via broadcast.
// It associates a consensus value with a proposal.
// The associated proposal is derivable from the basis.
// Travels on network.
struct ConsensusBasis {
  ExtensionPoint ext;
  ConsensusValue value;
  ProposalTxs proposal_txs;
};

} // namespace hogd
