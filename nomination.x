// clang-format off
%#include "discovery.hh"
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
  SignedTransactionHash transaction_hashes<>;
  NominatedTransaction transaction_nominations<>;
};

struct NominationTxsOnly {
  SignedTransactionHash transaction_hashes<>;
  NominatedTransaction transaction_nominations<>;
};

struct PrevNominationSummary {
  BlockHash block_hash;
};

} // namespace hogd
