// clang-format off
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]

struct ConsensusValue {
  ExtensionPoint ext;
  ValidatorID proposer;
  Upgrade upgrades<6>;
  ProposalHeader proposal_header;
  ProposalHash proposal_hash;
  ConsensusValueHash prev_value_hash;
};

struct ConsensusBasis {
  ConsensusValue value;
  ProposalTxs proposal_txs;
};

} // namespace hogd
