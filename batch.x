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

  // A "bag" contains a set of signed transactions.

  typedef SHA256Hash BagHash;

  struct BagSet {
    BagHash bag_hash;
    opaque bag_bitmap<>;
  };

  struct BagTransactions {
    SignedTransaction transactions<>;
  };

  struct BagMessage {
    BagTransactions bag_transactions;
  };

} // namespace hogd
