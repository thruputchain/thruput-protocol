// clang-format off
%#include "types.hh"
%#include "transaction.hh"

namespace hogd {
  // clang-format on

  // A "batch" contains a set of proposed transactions.

  typedef SHA256Hash BatchHash;

  struct BatchTransactions {
  ProposedTransaction transactions<>;
};

struct BatchMessage {
  BatchTransactions batch_transactions;
};

} // namespace hogd
