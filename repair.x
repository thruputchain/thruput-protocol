// clang-format off
%#include "consensus.hh"
%#include "discovery.hh"
%#include "nomination.hh"
%#include "scp.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct RepairConfig {
  Milliseconds base_delay_msec;
  Milliseconds max_delay_msec;
  unsigned int multiplier_nom;
  unsigned int multiplier_denom;
};

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

    OptConsensusValue repair_missing_cv(ConsensusValueHash, BlockHeight) = 20;

    SCPEnvelopes repair_missing_scp_envelopes(SCPSlotIndex) = 30;
  }
  = 1;
}
= 0x2233cccc;

} // namespace hogd
