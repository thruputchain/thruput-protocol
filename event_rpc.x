%#include "event.hh"
%#include "rpc_types.hh"

namespace hogd {

program ExecutorEvent
{
  version ExecutorEvent1
  {
    void executorevent_null(void) = 0;

    // A transaction should not call this more than once
    // We don't technically need the transaction ID here;
    // however, this will help later with tracing RPC calls through the system,
    // and helps in testing.
    RPCError executorevent_emit_event(BlockID, TransactionID, TxEventLog) = 30;
  } = 1;
} = 0x8aa81224;

union EventBlockResult switch (RPCError error) {
case kRPCNone:
  SHA256Hash root_hash;
default:
  void;
};

program CoordEvent
{
  version CoordEvent1
  {
    void coordevent_null(void) = 0;

    void coordevent_open_block(BlockID) = 10;
    EventBlockResult coordevent_close_block(BlockID) = 20;
  } = 1;
} = 0x8aa81225;

} // namespace hogd

