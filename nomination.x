// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// XXX(petar): Nomination should be renamed to Proposal
struct Nomination {
  BlockHeader block_header;
  ParallelSignedTransactionHashBatch transactions_hash;
  ParallelNondeterministicProposalDataBatch transactions_nondeterministic_data;
};

struct PrevNominationSummary {
  BlockHash block_hash;
};

} // namespace hogd
