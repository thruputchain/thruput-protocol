namespace hogd {

/// Flags that modify the behavior of a contract invocation.
///
/// These flags are used with the Invoke syscall to control how a subinvocation
/// executes. They are combined using bitwise OR.
///
/// Note: InvokeFlagSet is NOT part of the Invocation struct itself, but is
/// instead a parameter to the Invoke syscall. The root transaction invocation
/// always has no flags set (equivalent to None).
enum InvokeFlag {
  /// No special behavior (default).
  None = 0,

  /// Enable early conflict detection for parallel execution.
  ///
  /// Thruput executes transactions in parallel without observing other
  /// transactions' writes. After execution, a two-phase commit process commits writes
  /// to the database. If there's a conflict, the entire transaction aborts.
  ///
  /// TryInvoke pulls this conflict detection earlier: when a try_invoke frame
  /// finishes, it performs two-phase commit lock acquisition immediately. If any lock fails,
  /// the subinvocation frame reverts (but the caller can handle this gracefully).
  ///
  /// This is nondeterministic, so the two-phase commit result (a boolean) is appended to
  /// the nondeterministic_bits in [`NondeterministicProposalData`] for deterministic
  /// re-execution by validators.
  TryInvoke = 0x00000001,

  /// Prevent all state modifications in the subinvocation.
  ///
  /// The subinvocation can read storage but cannot write, deploy contracts,
  /// or perform any other state-modifying operations.
  ReadOnly = 0x00000002,

  /// Execute the target contract's code in the caller's context.
  ///
  /// Similar to Ethereum's DELEGATECALL: the invoked code runs with the
  /// caller's storage and address context, allowing library-like code reuse.
  ///
  /// TODO: This flag is not yet implemented. When implementing, provide
  /// a comprehensive specification of what changes and what doesn't change in
  /// a delegatecall frame. For example, GetMsgSender and GetCurrentAddress
  /// should NOT change (they return the original caller and current address),
  /// but storage operations should operate on the caller's storage. Document
  /// the behavior of all syscalls in a delegatecall context.
  DelegateCall = 0x00000004
};

/// A bitset of InvokeFlag values.
///
/// Multiple flags can be combined using bitwise OR. For example:
/// `ReadOnly | TryInvoke`
///
/// Unsigned because it holds bits, not a number, even though InvokeFlag,
/// like every XDR enum, is a signed int.
typedef unsigned int InvokeFlagSet;

} // namespace hogd