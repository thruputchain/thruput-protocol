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
  Protocol protocol;
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
  // fails, or tx_hashes/tx_nondeterministic counts do not match).
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
  SignedTransactionHash missing_tx_hashes<>;
  
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
  SchedulerCommitInvalidConsensusValue = 2
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

    // TODO(jhumphri): Remove this once we integrate the coordinator into the
    // loadgen experiment.
    DbSchedResult schedcoord_load_genesis_configuration(GenesisConfiguration) = 8;

    // Returns transactions from the mempool that have not yet been committed in a block.
    OptSignedTransactionBatch schedcoord_lookup_transactions(SignedTransactionHashBatch) = 100;
  }
  = 1;
}
= 0x76671111;

} // namespace hogd
