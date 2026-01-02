// clang-format off
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct ParallelBatch {
  unsigned int segment_tokens<>;
  unsigned int segment_bytes<>;
  opaque xdr<>;
};

typedef ParallelBatch ParallelSignedTransactionBatch;
typedef ParallelBatch ParallelSignedTransactionHashBatch;
typedef ParallelBatch ParallelNondeterministicProposalDataBatch;

} // namespace hogd
