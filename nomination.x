// clang-format off
%#include "discovery.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef SHA256Hash BlockHash;

struct Nomination {
  ValidatorPublicInfo proposer;
  BlockHeight block_height;
  BlockHash block_hash;
  BlockHash prev_block_hash;
  SignedTransactionHash transaction_hashes<>;
  NominatedTransaction transaction_nominations<>;
};

struct PrevNominationSummary {
  BlockHash block_hash;
};

} // namespace hogd
