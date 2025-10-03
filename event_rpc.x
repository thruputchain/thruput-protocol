%#include "event.hh"
%#include "rpc_types.hh"

namespace hogd {

program ExecutorEvent
{
  version ExecutorEvent1
  {
    void executorevent_null(void) = 0;

    // Error returned if the coordinator has not already opened the block
    RPCError executorevent_open_block(BlockID) = 10;
    RPCError executorevent_close_block(BlockID) = 20;

    // A transaction should not call this more than once
    RPCError executorevent_emit_event(BlockID, TxEventLog) = 30;
  } = 1;
} = 0x8aa81224;

program CoordEvent
{
  version CoordEvent1
  {
    void coordevent_null(void) = 0;

    void coordevent_open_block(BlockID) = 10;
    SHA256Hash coordevent_close_block(BlockID) = 20;
  } = 1;
} = 0x8aa81225;

} // namespace hogd

