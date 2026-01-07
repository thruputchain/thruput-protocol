// clang-format off
%#include "exec_sched.hh"
%#include "rpc_types.hh"
%#include "nomination.hh"
%#include "transaction.hh"
namespace hogd {
// clang-format on

struct SchedulerNomination {
  BlockID block_id;
  Nomination nomination;
};

struct SchedulerNominationChunk {
  unsigned int chunk_idx;
  unsigned int total_chunks;
  SchedulerNomination chunk;
};

// API exposed from the Coordinator for the Scheduler
program CoordScheduler
{
  version CoordScheduler1
  {
    void coordscheduler_null(void) = 0;

    // The scheduler calls coordscheduler_notify_vetted to indicate that the
    // given transactions are vetted, meaning the coordinator can broadcast
    // them to the network.
    void coordscheduler_notify_vetted(SignedTransactionBatch) = 1;
  }
  = 1;
}
= 0x11117667;

} // namespace hogd
