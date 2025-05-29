// clang-format off
%#include "types.hh"
%#include "transaction.hh"

namespace hogd {
  // clang-format on

  struct SubmittedTransactions {
    SignedTransaction transactions<>;
  };

} // namespace hogd
