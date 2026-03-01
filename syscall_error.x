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

  // ===== Error codes that signal the called frame reverted =====

  /// Deterministic error within called wasm (i.e. trap)
  kSyscallErrorCodeDeterministicWasm = -1,

  /// Child call frame manually reverted
  kSyscallErrorCodeFrameReverted = -2
};

} // namespace hogd
