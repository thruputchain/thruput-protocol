// clang-format off
%#include "db_sched.hh"
%#include "exec_sched.hh"
%#include "rpc_types.hh"
%#include "transaction.hh"
namespace hogd {
// clang-format on

enum CoordinatorRegistrationOutcome {
  CoordinatorRegistrationOK = 0,
  CoordinatorRegistrationInvalidProtocol = 1,
  CoordinatorRegistrationAlreadyRegistered = 2
};

struct CoordCard {
  ProtocolCommit protocol;
  ServerAddress address_for_sched;
};

enum SchedulerProposalOutcome {
  SchedulerProposalOK = 0,
  SchedulerProposalError = 1
};

struct SchedulerProposedBlock {
  BlockID block_id;
  ParallelSignedTransactionBatch txs;
  Proposal proposal;
};

union SchedulerProposalResult switch (SchedulerProposalOutcome outcome)
{
case SchedulerProposalOK:
  SchedulerProposedBlock proposed_block;
case SchedulerProposalError:
  void;
};

enum SchedulerValidationOutcome {
  SchedulerValidationOK = 0,
  SchedulerValidationInvalid = 1,
  SchedulerValidationMissingTxs = 2,
  SchedulerValidationDbFailed = 3,
  SchedulerValidationExecutorFailed = 4,
  SchedulerValidationTooLateToValidate = 5,
  SchedulerValidationUnknownParentBlock = 6,
  // Proposal batch metadata is malformed or fails to decode (e.g.
  // segment token/byte counts are inconsistent, XDR deserialization
  // fails, or signed_hash/nondeterministic_data counts do not match).
  SchedulerValidationMalformed = 7
};

struct SchedulerValidationBlock {
  BlockID block_id;
  ParallelSignedTransactionBatch signed_transactions;
};

union SchedulerValidationResult switch (SchedulerValidationOutcome outcome)
{
case SchedulerValidationOK:
  SchedulerValidationBlock block;
case SchedulerValidationMissingTxs:
  // The proposal's transactions this mempool does not hold in the proposed
  // encoding, including bodies it holds under a different signing.
  SignedTransactionHash missing_signed_tx_hashes<>;

// Error cases
case SchedulerValidationDbFailed:
case SchedulerValidationExecutorFailed:
case SchedulerValidationInvalid:
case SchedulerValidationTooLateToValidate:
case SchedulerValidationUnknownParentBlock:
case SchedulerValidationMalformed:
  void;
};

enum SchedulerCommitOutcome {
  SchedulerCommitOK = 0,
  SchedulerCommitBlockNotFound = 1,
  SchedulerCommitInvalidConsensusValue = 2,
  SchedulerConcurrentCommit = 3
};

enum SchedulerGetTipOutcome {
  SchedulerGetTipOK = 0,
  SchedulerGetTipNoGenesisBlock = 1
};

union SchedulerGetTipResult switch (SchedulerGetTipOutcome outcome)
{
case SchedulerGetTipOK:
  DbTip db_tip;
case SchedulerGetTipNoGenesisBlock:
  void;
};

struct GenesisCeremonyRequest {
  BlockHeight expected_parent_height;
  ConsensusValueHash expected_parent_value_hash;
  ProposalContext context;
  ParallelSignedTransactionBatch transactions;
};

enum GenesisCeremonyOutcome {
  GenesisCeremonyCommitted = 0,
  GenesisCeremonyParentMismatch = 2,
  GenesisCeremonyBatchMismatch = 3,
  GenesisCeremonyInvalidTransaction = 4,
  GenesisCeremonyExecutionFailed = 5
};

struct GenesisCeremonyCommit {
  DbTip db_tip;
  ProposalTxs proposal_txs;
};

enum SchedulerTransactionStatus {
  // The transaction is not pending and has no retained outcome. Note that the
  // tx *may* have existed at some point in the past, but has since been dropped
  // altogether from the mempool since the bounded queue filled. This not-found
  // status does not necessarily mean the tx has never existed at all.
  SchedulerTransactionNotFound = 0,
  // The transaction is currently pending in the mempool.
  SchedulerTransactionPending = 1,
  // The transaction was successfully committed in a block. This status does
  // *not* mean that the tx was successfully included in a proposed block or a
  // verified block--the block needs to go on to actually be committed.
  SchedulerTransactionSucceeded = 2,
  // Processing failed for a retryable reason; the transaction may be
  // resubmitted. Note that it is the responsibility of the wallet owner to
  // resubmit the tx--the mempool will not retry the tx on its own.
  SchedulerTransactionRetry = 3,
  // Processing failed permanently; the transaction should not be resubmitted
  // because the error is irrecoverable (e.g., failed authentication). The tx
  // needs to be modified in some way before it can be successfully processed.
  SchedulerTransactionDropped = 4
};

enum SchedulerTransactionErrorSource {
  // There is no error to report.
  SchedulerTransactionErrorNone = 0,

  // The error was triggered by the authentication subsystem.
  SchedulerTransactionErrorAuth = 1,
  // The error was triggered by the mempool.
  SchedulerTransactionErrorScheduler = 2,
  // The error was triggered by an executor.
  SchedulerTransactionErrorExecutor = 3
};

enum SchedulerErrorCode {
  // The mempool had no capacity to admit the transaction.
  SchedulerErrorCapacity = 1,
  // The scheduler could not obtain the account's average native-token age.
  SchedulerErrorNativeTokenAgeUnavailable = 2,
  // The transaction's expiry block height is earlier than the current block.
  SchedulerErrorExpired = 3,
  // The transaction's gas limit exceeds the account's available native tokens.
  SchedulerErrorInsufficientNativeTokens = 4
};

struct SchedulerTransactionOutcome {
  // The tx status. If the status is an error, then [error_source] and
  // [error_code] are filled in below. If the status is not an error, then
  // [error_source] and [error_code] have unspecified values.
  SchedulerTransactionStatus status;

  // Identifies the enum represented by [error_code] below.
  //
  // - None ([SchedulerTransactionErrorNone]): there was no error and
  //   [error_code] has an unspecified value.
  //
  // - Auth, Scheduler, and Executor: [error_code] is an [AuthErrorCode],
  //   [SchedulerErrorCode], or [ExecResult], respectively.
  SchedulerTransactionErrorSource error_source;

  // The actual error.
  int error_code;

  // For [SchedulerTransactionSucceeded], the committed block height.
  // For [SchedulerTransactionRetry] or [SchedulerTransactionDropped], the
  // proposal height for an executor failure, or the current chain height for
  // an admission/scheduler failure.
  // For [SchedulerTransactionPending], the current chain height at lookup.
  // Unspecified for [SchedulerTransactionNotFound].
  // Zero is a valid height.
  BlockHeight height;
};

typedef SchedulerTransactionOutcome SchedulerTransactionOutcomeBatch<>;

union GenesisCeremonyResult switch (GenesisCeremonyOutcome outcome)
{
case GenesisCeremonyCommitted:
  GenesisCeremonyCommit commit;
default:
  void;
};

// API exposed from the Scheduler for the Coordinator
program SchedulerCoord
{
  version SchedulerCoord1
  {
    void schedulercoord_null(void) = 0;

    CoordinatorRegistrationOutcome schedulercoord_intro_coord(CoordCard) = 1;

    // Coordinator calls schedulercoord_submit_unvetted to submit new/unvetted
    // transactions coming from the wallet. Asynchronously, the scheduler will
    // call the coordinator's coordscheduler_notify_vetted to notify the
    // coordinator when transactions have become vetted and can be broadcast
    // to the network.
    void schedulercoord_submit_unvetted(ParallelSignedTransactionBatch) = 2;
    void schedulercoord_submit_vetted(ValidatorID, ParallelSignedTransactionBatch) = 3;

    // schedulercoord_propose asks the scheduler to prepare a proposal (a
    // block proposal) on top of the given db block.
    SchedulerProposalResult schedulercoord_propose_block(BlockID, ProposalContext) = 4;

    // schedulercoord_validate asks the scheduler to validate a proposal,
    // and if successful, return the block ID in the db of the validated
    // block. BlockID is the block onto which the proposal is done.
    SchedulerValidationResult schedulercoord_validate_block(BlockID, Proposal) = 5;

    // Commit the block with block ID. This block must have been previously
    // proposed or validated by the mempool.
    // On commit the block is associated with the ConsensusValue that confirmed it.
    // This value is saved in the database and retrievable via schedcoord_get_tip.
    SchedulerCommitOutcome schedulercoord_commit_block(BlockID, ConsensusValue) = 6;

    // Returns information about the current highest committed block.
    // If there is no committed block, returns SchedulerGetTipNoGenesisBlock.
    SchedulerGetTipResult schedcoord_get_tip(void) = 7;

    DbSchedResult schedcoord_load_genesis_configuration(GenesisConfiguration) = 8;

    GenesisCeremonyResult schedulercoord_commit_genesis_ceremony(
      GenesisCeremonyRequest) = 10;

    // Returns transactions from the mempool that have not yet been committed in a block,
    // by their exact signed encoding.
    OptSignedTransactionBatch schedcoord_lookup_transactions(SignedTransactionHashBatch) = 100;

    // Returns one pending or recent outcome per input hash (same order).
    SchedulerTransactionOutcomeBatch schedcoord_lookup_transaction_outcomes(TransactionHashBatch) = 101;
  }
  = 1;
}
= 0x76671111;

} // namespace hogd
