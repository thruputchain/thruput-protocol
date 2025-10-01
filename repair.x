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

struct MissingTransactionsEnvelope {
  ValidatorID signer;
  Signature signature;
  MissingTransactions missing_transactions;
};

struct RepairedTransactions {
  SignedTransaction transactions<>;
};

program Repair
{
  version Repair1
  {

    void repair_null(void) = 0;

    RepairedTransactions repair_missing_txs(MissingTransactionsEnvelope) =
    10;
  }
  = 1;
}
= 0x2233cccc;

} // namespace hogd
