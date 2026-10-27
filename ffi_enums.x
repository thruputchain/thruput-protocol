namespace hogd {

// Error codes returned from a contract invocation.
// This is the external interface to a smart contract. Normally wrapped in an
// InvokeStatus<int32_t> (a std::expected).
//
// When InvokeStatus<int32_t> has an int32_t value (and an
// InvokeErrorCode::None), the int32_t value represents a handleable
// (deterministic) result from the invocation. (Specifically, the invoke()
// syscall in a nested smart contract invocation passes an
// {InvokeErrorCode::None, code} back as a
// {HostFnErrorCode::NoneOrRecoverable, code}).
//
// This value is either the value returned by the contract's entry point, the
// code caused by a host function returning HostFnErrorCode::Exit, or 0, if
// invocation ends because a host function returns HostFnErrorCode::Return.
enum InvokeErrorCode {
  // A call frame can only succeed if this code is returned.
  // All others revert the call frame.
  None = 0,
  // An unspecified deterministic error.
  Deterministic = 1,
  // Runtime exceeded its gas budget.
  OutOfGas = 2,
  // Nondeterministic error during invocation (e.g. malloc error)
  // Signals a serious system issue or a serious bug in our code and should be
  // diagnosed ASAP.
  Unrecoverable = 3,
  // Discovered during validation that proposer submitted bad data.
  // If a block contains a transaction with this error, the block does not need
  // to be discarded.  The transaction that causes this error is discarded,
  // and the block proposer should be penalized (via whatever out of band
  // mechanism),
  // but the rest of the block can still be processed.
  // Note that this is different from the case of a block proposal with
  // conflicting transactions;
  // those errors are discovered _after_ executing the transactions in a block,
  // and require
  // discarding the entire block.
  ValidationFailure = 4,
  // The transaction was aborted due to an external reason (such as the current
  // block being discarded),
  // but this is not the result of a totally unrecoverable error. This is to be
  // expected during normal system operation.
  Abandon = 5
};

// HostFunctionErrorCode categorizes errors returned from system calls. The
// normal usage pattern is to wrap them within HostFnStatus<int32_t>, where the
// int32 is the more detailed error code.
//
// A host function is one the contract runtime provides to the contract; system
// calls are made through host functions.
//
// When a HostFnStatus<int32_t> (a wrapper around std::expected) has an int32_t
// value, (and a HostFnErrorCode::NoneOrRecoverable), that int32_t is passed to
// the contract as a handleable error code, as the return result from the host
// function. The contract itself never sees the HostFnErrorCode. Other
// HostFnErrorCodes terminate the contract (returning to the caller), and are
// handled by the contract runtime.
enum HostFnErrorCode {
  NoneOrRecoverable = 0,
  // Insufficient gas to continue contract execution.
  //
  // Result: the contract runtime immediately returns an
  // InvokeErrorCode::OutOfGas.
  OutOfGas = 1,
  // Unrecoverable (nondeterministic) error, such as a malloc error.
  // The only course of action is to abort the entire transaction.
  //
  // Result: the contract runtime immediately returns an
  // InvokeErrorCode::Unrecoverable
  // Signals a serious system issue or a serious bug in our code and should be
  // diagnosed ASAP.
  Unrecoverable = 2,
  // Return from a contract invocation to the caller.  Registers a byte
  // buffer to be passed back to the caller.
  //
  // Result: Runtime immediately returns an {InvokeErrorCode::None, 0}.
  Return = 3,
  // Return from a contract invocation to the caller, with some (int32_t)
  // error code.
  //
  // Result: Runtime immediately returns an {InvokeErrorCode::None, code}.
  //
  // On a root smart contract invocation, a nonzero code is converted to a
  // InvokeErrorCode::Deterministic.
  Exit = 4,
  // Validation fails because a proposer submitted bad nondeterministic
  // proposal data.
  //
  // Result: the contract runtime immediately returns an
  // InvokeErrorCode::ValidationFailure
  ValidationFailure = 5,
  // The transaction was aborted due to an external reason (such as the current
  // block being discarded), but this is not the result of a totally
  // unrecoverable error. This is to be expected during normal system operation.
  //
  // Result: the contract runtime immediately returns an
  // InvokeErrorCode::Abandon
  Abandon = 6
};

// General-purpose system error codes returned from within various executor operations.
// These can be mapped into either InvokeErrorCode or HostFnErrorCode, depending on the context in which the
// error occurs.
enum SystemErrorCode {
  // Unrecoverable error (e.g. out of memory, or critical logic error).
  // Only recourse is to abort entire transaction and possibly crash binary.
  // Signals serious error, which we should investigate.
  // This converts to InvokeErrorCode::Unrecoverable or HostFnErrorCode::Unrecoverable.
  Unrecoverable = 1,
  // Nondeterministic error that occurs during normal course of operation.
  // E.g. a transaction is being executed concurrently with the whole block
  // getting cancelled.
  // Only recourse is to abort the entire transaction.
  // This converts to InvokeErrorCode::Abandon or HostFnErrorCode::Abandon.
  Abandon = 2,
  // Failure during validation of a transaction.  Signals that the whole
  // block must be aborted.
  // This converts to InvokeErrorCode::ValidationFailure or HostFnErrorCode::ValidationFailure.
  ValidationFailure = 3
};

} // namespace hogd
