// clang-format off
%#include "types.hh"
%#include "rpc_types.hh"
%#include "sc_val.hh"

namespace hogd {
// clang-format on

// The event format puts the first N * 32 bytes of the data
// as the topics.

/// Maximum length in bytes for a serialized event.
/// Events exceeding this length will be rejected by the LogEvent syscall.
const kMaxEventLength = 1024; // #[rust(const=u32)]

/// Maximum number of topics that can be attached to an event.
/// Topics enable efficient indexing and filtering of events.
const kMaxTopics = 3;

/// A 32-byte topic used for event indexing.
/// Topics are prepended to the serialized event data. The num_topics field
/// indicates how many of the leading 32-byte chunks are topics (up to kMaxTopics).
/// Downstream indexers use topics to efficiently filter events without deserializing.
typedef opaque Topic[32]; // #[rust(newtype)]

/// An event emitted by a contract during transaction execution.
/// Events are logged via the LogEvent syscall and stored in the transaction's event log.
///
/// The serialized_event field contains topic0 || topic1 || topic2 || data, where
/// the number of topic fields depends on num_topics.
/// This structure is the minimum unit forwarded to downstream indexing systems.
struct TxEmittedEvent {
  ContractAddress contract_address;
  unsigned int num_topics; // <= kMaxTopics
  opaque serialized_event<kMaxEventLength>;
};

/// Event log for a single transaction, stored in the merkle-patricia trie.
/// The key is the proposed_tx_hash, and the value is the complete list of
/// events emitted by that transaction. This structure enables efficient
/// querying of all events associated with a specific transaction.
struct TxEventLog {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  TxEmittedEvent events<>;
};

/// Complete identification of a unique event within the blockchain.
/// This structure is not constructed during the main transaction workflow; instead,
/// it may be produced by downstream systems (indexers, APIs) that cross-reference
/// events across transactions and blocks.
/// The combination of proposed_tx_hash and sequence_number uniquely identifies
/// any event. The sequence_number distinguishes multiple events emitted by
/// the same transaction.
struct IdentifiedEvent {
  SHA256Hash proposed_tx_hash; // sha256(ProposedTransaction)
  unsigned int sequence_number; // uniquifies the event
  TxEmittedEvent emitted_event;
};

} // namespace hogd
