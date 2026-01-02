// clang-format off
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct ParallelSignedTransactionBatch {
  unsigned int index<>;
  opaque xdr<>;
};

struct ParallelSignedTransactionHashBatch {
  unsigned int index<>;
  opaque xdr<>;
};

struct ParallelNondeterministicProposalDataBatch {
  unsigned int index<>;
  opaque xdr<>;
};

} // namespace hogd
