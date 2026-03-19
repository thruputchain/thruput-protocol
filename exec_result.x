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
  // One or more [GasClaim]s in the transaction were not validated with a
  // corresponding [sponsor_gas()] system call in a contract.
  ExecResultFailedGasSponsorship = 100,
  // Validation on the transaction has failed because the attached validation
  // data is bad. E.g. missing data or unused data. This error code is only
  // returned during validation. This is determininistic, but signals a bad
  // block from a malicious proposer.
  ExecResultTxValidationFailure = 200,
  // System error; network connection broke, etc.
  // Executor can recover from this error to continue execution of other
  // transactions.
  ExecResultSystemError = 300,
  // Critical failure in the executor, which cannot be recovered from.
  // E.g. OOM or critical logic error.
  ExecResultUnrecoverable = 400
};

}
