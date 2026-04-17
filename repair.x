// clang-format off
%#include "consensus.hh"
%#include "discovery.hh"
%#include "nomination.hh"
%#include "scp.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct MissingTransactions {
  SignedTransactionHash transaction_hashes<>;
  BlockHeight height;
  ConsensusValueHash cv_hash;
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

    OptConsensusValue repair_missing_cv(ConsensusValueHash, BlockHeight) = 20;

    SCPEnvelopes repair_missing_scp_envelopes(SCPSlotIndex) = 30;
  }
  = 1;
}
= 0x2233cccc;

} // namespace hogd
