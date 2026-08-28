// clang-format off

namespace hogd {
// clang-format on

// triple slash comments are added to the generated rust docs

/// Error codes returned by system calls.
/// Each syscall can return a specific subset of these error codes.
/// Check the syscalls.yaml documentation for which errors each syscall can return.
enum SyscallErrorCode {
  /// No error
  kSyscallErrorCodeNone = 0,

  /// Out of bounds pointer to wasm memory passed to syscall
  kSyscallErrorCodeFault = 1,

  /// System call for supplied number is not supported
  kSyscallErrorCodeNoSyscall = 2,

  /// Cannot call get_msg_sender on root invocation
  kSyscallErrorCodeIsRootTransaction = 3,

  /// Reentrance guard violation
  kSyscallErrorCodeReentrance = 4,

  /// Attempt made to deploy a contract twice (same nonce and contract hash, from
  /// same address)
  kSyscallErrorCodeContractAlreadyDeployed = 5,

  /// No return buffer is available.  Either the most recent subcall failed, or
  /// there have been no subcalls within this call frame.
  kSyscallErrorCodeNoReturnBufferAvailable = 6,

  /// Invalid input to a syscall, such as subtracting below 0 on an nnint64
  /// or a bytestring that is too long
  kSyscallErrorCodeInvalidSyscallInput = 7,

  /// Accessing a storage key that does not exist in the current view
  kSyscallErrorCodeStorageKeyNotExist = 8,

  /// No entry in the retrocausal queue to consume
  kSyscallErrorCodeNoRetrocausalQueueEntry = 9,

  /// The transaction has reached its per-transaction limit on concurrent
  /// retrocausal-queue reads (kMaxConcurrentRcqReadsPerTx). This is a resource
  /// limit, not a malformed call, and does not by itself fail the transaction;
  /// a contract may use it as a stop condition (e.g. drain a queue until it
  /// returns this).
  kSyscallErrorCodeRetrocausalQueueReadLimitReached = 10,

  /// The target of a DeleteObject is a retrocausal queue whose retained
  /// history spans more than kMaxRetrocausalQueueBlocksPerDeletion live block
  /// rows, so deleting it in one transaction would exceed the bounded
  /// commit-time cleanup budget. This is a resource limit, not a malformed
  /// call, and does not by itself fail the transaction; the contract can
  /// consume the queue down (pruning fully-consumed block rows) in earlier
  /// blocks and retry the delete.
  kSyscallErrorCodeRetrocausalQueueTooLargeToDelete = 11
};

} // namespace hogd
