%#include "event.hh"
%#include "rpc_types.hh"

namespace hogd {

program EventExecutor
{
  version EventExecutor1
  {
    void eventexecutor_null(void) = 0;

    // Called when executor opens a block - increments executor handle count
    RPCError eventexecutor_open_block(BlockID) = 31;

    // Called when executor closes its handle to a block - decrements count
    RPCError eventexecutor_close_block(BlockID) = 32;

    // A transaction should not call this more than once
    // We don't technically need the transaction ID here;
    // however, this will help later with tracing RPC calls through the system,
    // and helps in testing.
    RPCError eventexecutor_emit_event(BlockID, TransactionID, TxEventLog) = 30;
  } = 1;
} = 0x8aa81224;

union EventBlockResult switch (RPCError error) {
case kRPCNone:
  SHA256Hash root_hash;
default:
  void;
};

program EventSched
{
  version EventSched1
  {
    void eventsched_null(void) = 0;

    RPCError eventsched_open_block(BlockID) = 10;
    EventBlockResult eventsched_close_block(BlockID, BlockHeight) = 30;
    RPCError eventsched_abandon_block(BlockID) = 40;
  } = 1;
} = 0x8aa81226;

} // namespace hogd

