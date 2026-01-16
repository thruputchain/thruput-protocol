// clang-format off
%#include "types.hh"
%#include "rpc_types.hh"
%#include "sc_val.hh"

namespace hogd {

// The event format puts the first N * 32 bytes of the data
// as the topics.

const kMaxEventLength = 1024; // #[rust(const=u32)]
const kMaxTopics = 3;

typedef opaque Topic[32]; // #[rust(newtype)]

struct TxEmittedEvent {
  ContractAddress contract_address;
  unsigned int num_topics; // <= kMaxTopics
  opaque serialized_event<kMaxEventLength>;
};

// This is the struct that goes in the merkle-patricia trie.
// The key is the proposed_tx_hash field, and the value is the events field.
struct TxEventLog {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  TxEmittedEvent events<>;
};

// Information that suffices to uniquely identify an event.
// This information can be reconstructed from the TxEmittedEvent.
struct IdentifiedEvent {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  unsigned int sequence_number; // uniquifies the event
  TxEmittedEvent emitted_event;
};

} // namespace hogd
