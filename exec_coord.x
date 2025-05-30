// clang-format off
%#include "rpc_types.hh"
%#include "transaction.hh"
namespace hogd {
  // clang-format on

  enum ExecResult {
    ExecResultOK = 0,
    // Transaction execution (during proposal or validation) failed;
    // the error is deterministic and can be replayed in validation.
    // Transactions with this error code can be included in the block.
    ExecResultTxDeterministicError = 1,
    // Transaction execution (during proposal or validation) failed,
    // due to nondeterminism during the post-execution 2-phase commit.
    // Transactions with this error code should not be included in a proposal,
    // and indicate a block validation failure.
    ExecResultTxNonDeterministicError = 2,
    // System error; network connection broke, etc.
    // Executor can recover from this error to continue execution of other transactions.
    ExecResultSystemError = 3,
    // Critical failure in the executor, which cannot be recovered from.
    // E.g. OOM or critical logic error.
    ExecResultUnrecoverable = 4,
  };

  union ExecProposeResult switch (ExecResult result)
  {
  case ExecResultOK:
    NondeterministicProposalData proposal_data;
  default:
    void;
  };

  program ExecutorCoord
  {
    version ExecutorCoord1
    {

      void executorcoord_null(void) = 0;

      ExecProposeResult executorcoord_propose_transaction(BlockID,
                                                          SignedTransaction) =
          10;
      ExecResult executorcoord_validate_transaction(BlockID,
                                                    ProposedTransaction) = 20;

      // Executor can be in one of three states: None, Proposing, Validating
      // open_xyz_block() methods set the executor state, or return an error
      // if executor has already opened a block.
      // finish_block() blocks until all running executor threads are finished,
      // and stops the executor from accepting new transactions.
      ExecResult executorcoord_open_proposal_block(BlockID) = 30;
      ExecResult executorcoord_open_validation_block(BlockID) = 40;
      void executorcoord_finish_block(BlockID) = 50;

      // Coord should call this to shutdown the executor.
      // Shutdown will not occur until all pending transactions complete.
      // No new transactions or blocks can be opened after shutdown.
      void executorcoord_shutdown(void) = 60;
    }
    = 1;
  }
  = 0x7ee79999;

} // namespace hogd
