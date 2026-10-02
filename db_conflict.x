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
  ExclusiveLockDenied = 0,

  /// Two transactions created different item types at the same key.
  TypeMismatch = 1,

  /// Two transactions wrote irreconcilable values of the same type at the
  /// same key: different bytestrings, different nnint base values,
  /// different auth-data bases, or different contract / deployment hashes.
  ValueMismatch = 2,

  /// A nonnegative int would go below zero given the deltas in this block.
  /// A native HOG balance that cannot cover its debits reports
  /// InsufficientFunds instead.
  BoundsExceeded = 3,

  /// Integer overflow combining deltas on a nonnegative int or balance.
  Overflow = 4,

  /// Replay-protection conflict: uniquifier expired, already consumed (in
  /// a prior block or by a concurrent transaction), or consumed twice by
  /// this transaction.
  ReplayProtection = 5,

  /// A retrocausal queue already has a consumer in this block.
  QueueConsumer = 6,

  /// A per-item capacity limit was hit: replay-cache active heights or
  /// nonces, retrocausal-queue block entries, or auth signer slots.
  CapacityExceeded = 7,

  /// The native HOG balance at the diagnostic's address cannot cover the
  /// debits in this block, or a newly created balance item cannot cover
  /// its own storage cost. Storage written under a contract's address is
  /// charged to that contract's balance, so a deployment reports this at
  /// the new contract's address when it holds no HOG.
  InsufficientFunds = 8,

  /// An auth-data change would register a public key in a slot while
  /// another slot of the same address already holds that key, whether
  /// committed or set by the same change. The table would count one
  /// key's weight twice, so the change is refused.
  DuplicateSigner = 9
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

/// Reason the executor refused a transaction's contract attachments
/// (Transaction.contracts_to_deploy) at proposal time. Any of them drops the
/// transaction from the proposal; none is a contract fault. The RV32 codes
/// name which check of the artifact failed, so an author can tell a
/// toolchain/node mismatch from an oversized or corrupt build.
enum ContractRejectCode {
  /// The transaction attaches more contracts than the chain's
  /// max_new_contracts_per_tx permits.
  ContractRejectTooMany = 0,

  /// The contract blob exceeds the chain's max_contract_size_bytes.
  ContractRejectBlobTooLarge = 1,

  /// The attachment is not an RV32 contract. Native contracts are registered
  /// at genesis; RV32 is the only deployable type.
  ContractRejectNotDeployable = 2,

  /// The same contract is attached more than once.
  ContractRejectDuplicate = 3,

  /// The blob is not a readable RV32 artifact: too short, wrong magic, wrong
  /// header size, or its length disagrees with the section sizes the header
  /// declares.
  ContractRejectMalformedArtifact = 4,

  /// The artifact's format version is not the one this node reads.
  ContractRejectUnsupportedFormat = 5,

  /// The artifact's VM profile, flags, entry ABI, or syscall ABI is not one
  /// this node runs.
  ContractRejectUnsupportedAbi = 6,

  /// The gas schedule (version, digest) stamped into the artifact is not one
  /// the node accepts: the artifact was lowered by a toolchain whose gas
  /// schedule differs from the node's.
  ContractRejectGasScheduleMismatch = 7,

  /// The declared guest memory exceeds the chain's max_rv32_memory_bytes.
  ContractRejectMemoryTooLarge = 8,

  /// The code section is empty or exceeds the chain's max_rv32_code_bytes.
  ContractRejectCodeSizeInvalid = 9,

  /// The initial memory image does not fit in the declared guest memory, or
  /// an empty image declares a nonzero load address.
  ContractRejectInitialMemoryInvalid = 10,

  /// A section's bytes do not match the SHA-256 digest the header records.
  ContractRejectDigestMismatch = 11,

  /// The code does not translate: it contains an unsupported or malformed
  /// instruction.
  ContractRejectInvalidProgram = 12
};

/// The first contract attachment the executor refused.
struct ContractRejectDiagnostic {
  /// Position in Transaction.contracts_to_deploy of the refused contract.
  /// For ContractRejectTooMany, the first position past the limit.
  unsigned int contract_index;
  ContractRejectCode code;
};

enum TxFailureKind {
  /// Two-phase commit could not apply the transaction's storage deltas.
  TxFailureDbConflict = 0,
  /// The executor refused a contract attachment before execution.
  TxFailureContractRejected = 1
};

union TxFailureCause switch (TxFailureKind kind) {
case TxFailureDbConflict:
  DbConflictDiagnostic conflict;
case TxFailureContractRejected:
  ContractRejectDiagnostic contract;
};

/// Best-effort diagnostic for a transaction the proposer excluded from a
/// proposal: the executing block height of the failed attempt plus why it
/// failed -- the first conflicting storage op hog_db reported during
/// two-phase commit, or the first contract attachment the executor refused.
/// Fixed-size by construction; the wire and caches carry exactly one
/// diagnostic per failure to bound memory end to end.
struct TxFailureDiagnostic {
  BlockHeight attempt_height;
  TxFailureCause cause;
};

} // namespace hogd
