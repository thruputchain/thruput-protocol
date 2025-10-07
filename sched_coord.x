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
  BlockID current_block_id;
};

enum SchedulerNominationOutcome {
  SchedulerNominationOK = 0,
  SchedulerNominationError = 1,
};

struct SchedulerNomination {
  BlockID block_id;
  Nomination nomination;
};

union SchedulerNominationResult switch (SchedulerNominationOutcome outcome)
{
case SchedulerNominationOK:
  SchedulerNomination scheduler_nomination;
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
    void schedulercoord_submit_unvetted(SignedTransactionBatch) = 10;

    // Coordinator calls schedulercoord_submit_vetted to submit transactions
    // received from the network, which have been vetted by a given other
    // validator.
    void schedulercoord_submit_vetted(ValidatorID, SignedTransactionBatch) =
    20;

    // schedulercoord_nominate asks the scheduler to prepare a nomination (a
    // block proposal) on top of the given db block.
    SchedulerNominationResult schedulercoord_nominate(DbTip) = 30;

    // schedulercoord_validate asks the scheduler to validate a nomination,
    // and if successful, return the block ID in the db of the validated
    // block. DbTip is the block onto which the nomination is done.
    SchedulerValidationResult schedulercoord_validate(DbTip, Nomination) = 40;

    // Returns information about the current highest committed block.
    // If there is no committed block, returns DbSchedResultError.
    DbTipResult schedcoord_get_tip(void) = 50;

    // Load genesis block data into storage.
    // This calculates storage keys and stores allocation amounts as
    // bytestrings.
    DbSchedResult schedcoord_load_genesis_block(GenesisBlock) = 60;
  }
  = 1;
}
= 0x76671111;

} // namespace hogd
