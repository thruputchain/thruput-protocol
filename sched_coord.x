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
};

struct CoordCard {
  Protocol protocol;
  ServerAddress address_for_sched;
};

enum SchedulerNominationOutcome {
  SchedulerNominationOK = 0,
  SchedulerNominationError = 1,
};

struct SchedulerNominatedBlock {
  BlockID block_id;
  Nomination nomination;
};

union SchedulerNominationResult switch (SchedulerNominationOutcome outcome)
{
case SchedulerNominationOK:
  SchedulerNominatedBlock nominated_block;
default:
  void;
};

enum SchedulerValidationOutcome {
  SchedulerValidationOK = 0,
  SchedulerValidationInvalid = 1,
  SchedulerValidationMissingTxs = 2,
  SchedulerValidationDbFailed = 3,
  SchedulerValidationExecutorFailed = 4,
};

union SchedulerValidationResult switch (SchedulerValidationOutcome outcome)
{
case SchedulerValidationOK:
  DbTip db_tip;
case SchedulerValidationMissingTxs:
  SignedTransactionHash missing_tx_hashes<>;
default:
  void;
};

enum SchedulerCommitOutcome {
  SchedulerCommitOK = 0,
  SchedulerCommitBlockNotFound = 1,
  SchedulerCommitRace = 2
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

    // schedulercoord_nominate asks the scheduler to prepare a nomination (a
    // block proposal) on top of the given db block.
    SchedulerNominationResult schedulercoord_nominate(DbTip) = 4;

    // schedulercoord_validate asks the scheduler to validate a nomination,
    // and if successful, return the block ID in the db of the validated
    // block. DbTip is the block onto which the nomination is done.
    SchedulerValidationResult schedulercoord_validate(DbTip, Nomination) = 5;

    // Commit the block with block ID. This block must have been previously
    // nominated or validated by the mempool.
    SchedulerCommitOutcome schedulercoord_commit_block(BlockID) = 6;

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
