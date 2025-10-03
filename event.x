// clang-format off
%#include "types.hh"
%#include "rpc_types.hh"
%#include "sc_val.hh"

namespace hogd {

struct EventData {
  SHA256Hash topics<3>;
  opaque event<>;
};

// The structure of an event that is placed into our merkle-patricia trie
// For contracts that structure their data appropriately (specify the topic types, no more than 3 topics), 
// this can be converted into a stellar::ContractEvent.
struct Event {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  unsigned int sequence_number; // uniquifies the event
  ContractAddress contract_address;

  EventData data;
};

struct TxEmittedEvent {
  ContractAddress contract_address;
  opaque serialized_event<>;  // serialized EventData
};

struct TxEventLog {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  TxEmittedEvent events<>;
};

} // namespace hogd
