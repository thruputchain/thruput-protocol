%#include "consensus.hh"
%#include "network.hh"
%#include "rpc_types.hh"
%#include "types.hh"

namespace hogd {

// Uniquely describes an event server instance.
struct EventCard {
  ProtocolCommit protocol;
  UPID upid;
  ServerAddress address_for_exec;
  ServerAddress address_for_sched;
};

struct EventCanonicalTip {
  BlockID block_id;
  ConsensusValue consensus_value;
};

struct EventRegistrationSnapshot {
  EventCanonicalTip tip;
  unsigned hyper token;
};

enum EventPrepareOutcome {
  EventPrepareOK = 0,
  EventPrepareNotReady = 1,
  EventPrepareError = 2
};

union EventPrepareResult switch (EventPrepareOutcome outcome) {
case EventPrepareOK:
  EventRegistrationSnapshot snapshot;
default:
  void;
};

enum EventActivationOutcome {
  EventActivationOK = 0,
  EventActivationRetry = 1,
  EventActivationError = 2
};

union EventActivationResult switch (EventActivationOutcome outcome) {
case EventActivationRetry:
  EventCanonicalTip current_tip;
default:
  void;
};

program SchedEvent
{
  version SchedEvent1
  {
    EventPrepareResult schedevent_prepare_event(EventCard) = 1;
    EventActivationResult
    schedevent_activate_event(EventRegistrationSnapshot) = 2;
  }
  = 1;
}
= 0x7ee79998;

} // namespace hogd
