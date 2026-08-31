// clang-format off
%#include "rpc_types.hh"
%#include "transaction.hh"
%#include "exec_result.hh"
%#include "header.hh"
namespace hogd {
// clang-format on

union ExecProposeResult switch (ExecResult result)
{
case ExecResultOK:
case ExecResultTxDeterministicError:
case ExecResultTxRootFrameReverted:
  NondeterministicProposalData proposal_data;
default:
  void;
};

typedef ExecProposeResult ExecProposeBatchResult<>;
typedef ExecResult ExecValidateBatchResult<>;

program ExecutorSched
{
  version ExecutorSched1
  {

    void executorsched_null(void) = 0;

    ExecResult executorsched_ready(void) = 1;

    ExecProposeResult executorsched_propose_transaction(BlockID,
							SignedTransaction) =
    10;
    ExecResult executorsched_validate_transaction(BlockID,
						  ProposedTransaction) = 20;

    ExecProposeBatchResult executorsched_propose_batch(
      BlockID, SignedTransactionBatch) = 11;
    ExecValidateBatchResult executorsched_validate_batch(
      BlockID, ProposedTransactionBatch) = 21;

    // Executor can be in one of three states: None, Proposing, Validating
    // open_xyz_block() methods set the executor state, or return an error
    // if executor has already opened a block.
    // finish_block() blocks until all running executor threads are finished,
    // and stops the executor from accepting new transactions.
    //
    // Both open_xyz_block() methods take the same ProposalContext -- the
    // inputs fixed before the block executes -- so the executor sees an
    // identical view of the block whether it is proposing or validating,
    // and contract-visible block data (e.g. the GetBlockTimepoint syscall)
    // is served from one place. ProposalHeader is deliberately NOT the
    // argument here: its txs/storage/events/config hashes are outputs of
    // executing the block, so it does not exist yet at open time.
    //
    // The scheduler supplies the context from whichever side it is on:
    //   - proposing:  forwarded verbatim from the coordinator's
    //                 schedulercoord_propose_block(BlockID, ProposalContext).
    //   - validating: rebuilt from the proposal under validation, taking
    //                 proposer and block_timepoint from its ProposalHeader.
    //
    // A validator MUST take these from the proposal it is validating and
    // never regenerate them locally: the proposer's values are the ones its
    // execution committed to, so any divergence here diverges execution and
    // splits consensus.
    ExecResult executorsched_open_proposal_block(BlockID, ProposalContext) =
    30;
    ExecResult executorsched_open_validation_block(BlockID, ProposalContext) =
    40;
    ExecResult executorsched_finish_block(BlockID) = 50;

    // Scheduler should call this to shutdown the executor.
    // Shutdown will not occur until all pending transactions complete.
    // No new transactions or blocks can be opened after shutdown.
    void executorsched_shutdown(void) = 60;
  }
  = 1;
}
= 0x7ee79999;

} // namespace hogd
