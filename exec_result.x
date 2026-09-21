namespace hogd {

enum ExecResult {
  ExecResultOK = 0,
  // Transaction execution (during proposal or validation) failed.
  // Specifically, the root frame returned Deterministic.
  // the error is deterministic and can be replayed in validation.
  // Transactions with this error code can be included in the block.
  ExecResultTxDeterministicError = 1,
  // The root frame of the transaction chose to revert.
  // This error is deterministic and can be included in a block.
  // However, any changes within contract state are reverted.
  ExecResultTxRootFrameReverted = 2,
  // Transaction execution (during proposal or validation) failed,
  // due to nondeterminism during the post-execution 2-phase commit.
  // Transactions with this error code should not be included in a proposal,
  // and indicate a block validation failure.
  ExecResultTxNonDeterministicError = 3,
  // No longer used. Previously indicated that gas sponsorship claims were
  // not validated. Retained to avoid renumbering enum values.
  ExecResultFailedGasSponsorship = 100,
  // Validation on the transaction has failed because the attached validation
  // data is bad. E.g. missing data or unused data. This error code is only
  // returned during validation. This is determininistic, but signals a bad
  // block from a malicious proposer.
  ExecResultTxValidationFailure = 200,
  // The transaction is malformed: a structural check rejected it before
  // execution, on its contents alone and independent of ledger state.
  // This error code is only returned during proposal, where the scheduler
  // drops the transaction instead of including it in the block. The same
  // defect during validation is ExecResultTxValidationFailure, since a
  // malformed transaction inside a proposed block is the proposer's fault.
  ExecResultMalformedTransaction = 201,
  // System error; network connection broke, etc.
  // Executor can recover from this error to continue execution of other
  // transactions.
  ExecResultSystemError = 300,
  // Critical failure in the executor, which cannot be recovered from.
  // E.g. OOM or critical logic error.
  ExecResultUnrecoverable = 400
};

}
