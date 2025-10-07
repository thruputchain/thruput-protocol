// clang-format off
%#include "rpc_types.hh"
%#include "types.hh"

namespace hogd {

// clang-format on

// Uniquely describes an event server instance.
struct EventCard {
  Protocol protocol;
  UPID upid;
  ServerAddress address_for_exec;
  ServerAddress address_for_sched;
};

program SchedEvent
{
  version SchedEvent1
  {
    // [schedexec_intro_event] is called by an event server to introduce itself to
    // the system.
    RPCError schedevent_intro_event(EventCard) = 1;
  }
  = 1;
}
= 0x7ee79998;

} // namespace hogd
