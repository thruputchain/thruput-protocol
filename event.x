// clang-format off
%#include "types.hh"
%#include "rpc_types.hh"
%#include "sc_val.hh"

namespace hogd {

typedef SCVal Topic;

// The structure of an event that is placed into our merkle-patricia trie
struct Event {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  unsigned int sequence_number;
  ContractAddress contract_address;
  Topic topics<3>;

  // leaf of the trie
  opaque event<>;
};

struct TxEmittedEvent {
  ContractAddress contract_address;
  opaque event<>;
};

struct TxEventLog {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  TxEmittedEvent events<>;
};

program ExecutorEvent
{
  version ExecutorEvent1
  {
    void executorevent_null(void) = 0;

    // Error returned if the coordinator has not already opened the block
    RPCError executorevent_open_block(BlockID) = 10;
    RPCError executorevent_close_block(BlockID) = 20;

    RPCError executorevent_emit_event(BlockID, TxEventLog) = 30;
  }
  = 1;
}
= 0x8aa81224;

program CoordEvent
{
  version CoordEvent1
  {
    void coordevent_null(void) = 0;

    void coordevent_open_block(BlockID) = 10;
    SHA256Hash coordevent_close_block(BlockID) = 20;
  }
  = 1;
}
= 0x8aa81225;

} // namespace hogd
