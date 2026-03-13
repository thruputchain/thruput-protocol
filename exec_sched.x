// clang-format off
%#include "rpc_types.hh"
%#include "transaction.hh"
%#include "exec_result.hh"
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

typedef ProposedTransaction ProposedTransactionBatch<>;
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
      BlockID, TransactionBatch) = 11;
    ExecValidateBatchResult executorsched_validate_batch(
      BlockID, ProposedTransactionBatch) = 21;

    // Executor can be in one of three states: None, Proposing, Validating
    // open_xyz_block() methods set the executor state, or return an error
    // if executor has already opened a block.
    // finish_block() blocks until all running executor threads are finished,
    // and stops the executor from accepting new transactions.
    ExecResult executorsched_open_proposal_block(BlockID) = 30;
    ExecResult executorsched_open_validation_block(BlockID) = 40;
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
