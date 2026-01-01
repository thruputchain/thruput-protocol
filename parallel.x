// clang-format off
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// XXX: speed of decoding index?

struct ParallelSignedTransactionBatch {
  int index<>;
  opaque xdr<>;
};

struct ParallelSignedTransactionHashBatch {
  int index<>;
  opaque xdr<>;
};

struct ParallelNondeterministicProposalDataBatch {
  int index<>;
  opaque xdr<>;
};

} // namespace hogd
