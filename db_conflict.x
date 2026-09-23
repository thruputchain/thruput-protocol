// clang-format off

%#include "types.hh"

namespace hogd
{
// clang-format on

/// Reason a storage delta could not be applied during two-phase commit.
/// These are the nondeterministic failures of try_push_new_subtransaction:
/// any of them causes ExecResultTxNonDeterministicError, and the transaction
/// is excluded from the block. Codes are intentionally coarse; finer-grained
/// detail may be added later behind a debug-only extension.
enum DbConflictCode {
  /// Exclusive-lock collision: the key is exclusively locked by another
  /// transaction (committed or concurrent), an exclusive lock could not be
  /// acquired because other transactions hold the key, or an exclusive-lock
  /// flag was used on a key type that does not support it.
  kDbConflictExclusiveLock = 0,

  /// Two transactions created different item types at the same key.
  kDbConflictTypeMismatch = 1,

  /// Two transactions wrote irreconcilable values of the same type at the
  /// same key: different bytestrings, different nnint base values,
  /// different auth-data bases, or different contract / deployment hashes.
  kDbConflictValueMismatch = 2,

  /// A nonnegative int would go below zero given the deltas in this block.
  /// A native HOG balance that cannot cover its debits reports
  /// kDbConflictInsufficientFunds instead.
  kDbConflictBoundsExceeded = 3,

  /// Integer overflow combining deltas on a nonnegative int or balance.
  kDbConflictOverflow = 4,

  /// Replay-protection conflict: uniquifier expired, already consumed (in
  /// a prior block or by a concurrent transaction), or consumed twice by
  /// this transaction.
  kDbConflictReplayProtection = 5,

  /// A retrocausal queue already has a consumer in this block.
  kDbConflictQueueConsumer = 6,

  /// A per-item capacity limit was hit: replay-cache active heights or
  /// nonces, retrocausal-queue block entries, or auth signer slots.
  kDbConflictCapacityExceeded = 7,

  /// The native HOG balance at the diagnostic's address cannot cover the
  /// debits in this block, or a newly created balance item cannot cover
  /// its own storage cost. Storage written under a contract's address is
  /// charged to that contract's balance, so a deployment reports this at
  /// the new contract's address when it holds no HOG.
  kDbConflictInsufficientFunds = 8
};

/// How much conflict diagnostic detail try_push_new_subtransaction reports
/// on failure. Selected by the database from the block's execution mode:
/// proposal blocks report First (release builds) or All (debug builds);
/// validation and viewing blocks report None.
enum DbDiagnosticLevel {
  /// No diagnostics (validation / viewing; previous behavior).
  kDbDiagnosticNone = 0,
  /// Report only the first conflict encountered (proposal, release builds).
  kDbDiagnosticFirst = 1,
  /// Report a best-effort list of all conflicting deltas in the batch
  /// (proposal, debug builds — SDK testing).
  kDbDiagnosticAll = 2
};

/// One conflicting storage op. Fixed-size: ContractAddress[32] plus a
/// fixed-size StorageKey plus the code — no heap allocation.
struct DbConflictDiagnostic {
  AddressAndKey addrkey;
  DbConflictCode code;
};

/// Conflict diagnostics attached to a failed try_push_new_subtransaction.
/// The discriminant is the DbDiagnosticLevel the database selected from
/// the block's execution mode, so the variable-length arm is only ever
/// constructed in kDbDiagnosticAll mode (debug-build proposals); prod
/// levels are allocation-free by construction.
union DbConflictResult switch (DbDiagnosticLevel level) {
case kDbDiagnosticNone:
  void;
case kDbDiagnosticFirst:
  DbConflictDiagnostic first;
case kDbDiagnosticAll:
  DbConflictDiagnostic conflicts<>;
};

/// Best-effort diagnostic for a transaction that failed nondeterministically
/// during two-phase commit at proposal time: the executing block height of
/// the failed attempt plus the first conflicting storage op hog_db reported.
/// Fixed-size by construction; the wire and caches carry exactly one
/// diagnostic per failure to bound memory end to end.
struct TxFailureDiagnostic {
  BlockHeight attempt_height;
  DbConflictDiagnostic conflict;
};

} // namespace hogd
