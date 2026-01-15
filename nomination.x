// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// XXX(petar): Nomination should be renamed to Proposal
struct Nomination {
  ValidatorPublicInfo proposer;
  BlockHeight block_height;
  BlockHash block_hash; //XXX: rename to merkle_hash
  BlockHash prev_block_hash; //XXX: rename to prev_merkle_hash
  ParallelSignedTransactionHashBatch transactions_hash;
  ParallelNondeterministicProposalDataBatch transactions_nondeterministic_data;
};

struct PrevNominationSummary {
  BlockHash block_hash;
};

} // namespace hogd
