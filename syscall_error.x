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

  /// The invocation would exceed the network's cross-invoke depth bound
  /// (kConfigParamMaxCrossInvokeDepth), which limits how many invocation
  /// frames one transaction may hold open at once. Like the retrocausal-queue
  /// read limit this is a resource limit, not a malformed call: the same
  /// invocation succeeds from a shallower frame. It is reported before any
  /// child frame runs, so the syscall is a complete no-op and the caller's
  /// invoke outputs are left untouched.
  kSyscallErrorCodeInvokeDepthExceeded = 11,

  /// SponsorGas was called by a frame whose address no SponsorTerm names, or
  /// with an expected_amount that does not equal the amount that frame's term
  /// states. A contract can only ever assent to sponsorship the submitter
  /// offered it, for exactly the amount offered, so this reports both halves
  /// of that check.
  kSyscallErrorCodeSponsorshipNotOffered = 12,

  /// SponsorGas was called after some sponsor had already assented to this
  /// transaction. Sponsorship is one-shot per transaction.
  kSyscallErrorCodeSponsorshipAlreadyAssented = 13,

  /// SponsorGas was called by a frame whose address is named by a SponsorTerm
  /// it cannot currently fund. Checked at assent rather than only at commit,
  /// so a transaction naming one solvent and one insolvent sponsor fails
  /// immediately instead of running to completion and failing two-phase
  /// commit.
  kSyscallErrorCodeSponsorInsufficientHogs = 14
};

} // namespace hogd
