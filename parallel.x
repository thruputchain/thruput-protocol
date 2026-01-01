// clang-format off
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct ParallelSignedTransactionBatch {
  opaque index<>;
  opaque xdr<>;
};

struct ParallelSignedTransactionHashBatch {
  opaque index<>;
  opaque xdr<>;
};

struct ParallelNondeterministicProposalDataBatch {
  opaque index<>;
  opaque xdr<>;
};

} // namespace hogd
