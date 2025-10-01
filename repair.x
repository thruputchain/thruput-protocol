// clang-format off
%#include "discovery.hh"
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct MissingTransactions {
  SignedTransactionHash transaction_hashes<>;
  BlockHash block_hash;
};

struct RepairedTransactions {
  SignedTransaction transactions<>;
};

program Repair
{
  version Repair1
  {

    void repair_null(void) = 0;

    RepairedTransactions repair_missing_txs(MissingTransactions) =
    10;
  }
  = 1;
}
= 0x2233cccc;

} // namespace hogd
