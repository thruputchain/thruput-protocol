// clang-format off
%#include "catchup.hh"
%#include "consensus.hh"
%#include "discovery.hh"
%#include "proposal.hh"
%#include "scp.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// missing transactions (v1)

struct MissingTransactions {
  SignedTransactionHash transaction_hashes<>;
  ConsensusValue consensus_value;
};

struct MissingTransactionsEnvelope {
  ValidatorID signer;
  Signature signature;
  MissingTransactions missing_transactions;
};

struct RepairedTransactions {
  SignedTransaction transactions<>;
};

// missing transactions (v2)

struct MissingTxs {
  SignedTransactionHash tx_hashes<>;
  ConsensusValue consensus_value;
};

struct SignedMissingTxs {
  ValidatorID signer;
  Signature signature;
  MissingTxs missing_txs;
};

struct RepairedTxs {
  SignedTransaction txs<>;
};

struct SignedRepairedTxs {
  Signature signature;
  RepairedTxs repaired_txs;
};

// missing proposal structures (v2)

struct MissingProposal {
  ConsensusValue consensus_value;
};

struct SignedMissingProposal {
  ValidatorID signer;
  Signature signature;
  MissingProposal missing_proposal;
};

struct RepairedProposal {
  Proposal *proposal;
};

struct SignedRepairedProposal {
  Signature signature;
  RepairedProposal repaired_proposal;
};

// missing slot structures (v2)

struct MissingSlot {
  unsigned hyper slot;
};

struct SignedMissingSlot {
  ValidatorID signer;
  Signature signature;
  MissingSlot missing_slot;
};

typedef opaque SlotMessage<>;

struct RepairedSlot {
  SlotMessage slot_messages<>;
};

struct SignedRepairedSlot {
  Signature signature;
  RepairedSlot repaired_slot;
};

// missing block structures (v2)

struct MissingBlocks {
  CatchupSpan spans<>;
};

struct SignedMissingBlocks {
  ValidatorID signer;
  Signature signature;
  MissingBlocks missing_blocks;
};

struct RepairedBlocks {
  CatchupBlock blocks<>;
};

struct SignedRepairedBlocks {
  Signature signature;
  RepairedBlocks repaired_blocks;
};


program Repair
{
  version Repair1
  {

    void repair_null(void) = 0;

    RepairedTransactions repair_missing_txs(MissingTransactionsEnvelope) =
    10;

    OptProposal repair_missing_proposal(ConsensusValue) = 20;

    SCPEnvelopes repair_missing_scp_envelopes(SCPSlotIndex) = 30;
  }
  = 1;

  version Repair2
  {

    void repair_null(void) = 0;

    SignedRepairedTxs repair_missing_txs(SignedMissingTxs) =
    10;

    SignedRepairedProposal repair_missing_proposal(SignedMissingProposal) = 20;

    SignedRepairedSlot repair_missing_slot(SignedMissingSlot) = 30;

    SignedRepairedBlocks repair_missing_blocks(SignedMissingBlocks) = 40;
  }
  = 2;
}
= 0x2233cccc;

} // namespace hogd
