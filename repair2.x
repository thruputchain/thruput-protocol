// clang-format off
%#include "catchup.hh"
%#include "consensus.hh"
%#include "discovery.hh"
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// missing transactions (v2)

struct MissingTxs {
  TransactionHash tx_hashes<>;
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
  BlockHeight block_height;
  ConsensusValueHash value_hash;
};

struct SignedMissingProposal {
  ValidatorID signer;
  Signature signature;
  MissingProposal missing_proposal;
};

struct RepairedProposal {
  ConsensusBasis *basis;
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
  version Repair2
  {

    void repair_null(void) = 0;

    RepairedTxs repair_missing_txs(SignedMissingTxs) =
    10;

    RepairedProposal repair_missing_proposal(SignedMissingProposal) = 20;

    RepairedSlot repair_missing_slot(SignedMissingSlot) = 30;

    RepairedBlocks repair_missing_blocks(SignedMissingBlocks) = 40;
  }
  = 2;
}
= 0x2233cccc;

} // namespace hogd
