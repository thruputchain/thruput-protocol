// clang-format off
%#include "types.hh"
%#include "rpc_types.hh"
%#include "exec_result.hh"
%#include "sc_val.hh"
%#include "transaction.hh"

namespace hogd {
// clang-format on

// The event format puts the first N * 32 bytes of the data
// as the topics.

/// Maximum length in bytes for a serialized event.
/// Events exceeding this length will be rejected by the LogEvent syscall.
const kMaxEventLength = 1024; // #[rust(const=u32)]

/// Maximum number of events a single transaction may emit.
/// This keeps a single TxEventLog well below the RPC transport message limit.
const kMaxEventsPerTransaction = 1000; // #[rust(const=u32)]

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
/// The key is the tx_hash, and the value is the complete list of
/// events emitted by that transaction. This structure enables efficient
/// querying of all events associated with a specific transaction.
///
/// That key is the identity of the transaction the submitter signed, not of
/// the [`ProposedTransaction`] the proposer assembled from it, so a
/// submitter can compute it before submission and use it to find its own
/// events. The nondeterministic proposal data travels alongside the log to
/// the indexer and is not part of this commitment. See [`TransactionHash`].
///
/// `root_output` carries the InvocationFrameOutput of the transaction's
/// root frame: the Return buffer on success, the Abort buffer on a
/// deterministic revert, or the Fault variant when no root output was
/// produced (e.g., non-deterministic failure).  Downstream indexers and
/// the receipt-read paths surface this as `return_data`/`abort_data`.
struct TxEventLog {
  TransactionHash tx_hash; // sha256(Transaction)
  ExecResult exec_result;
  InvocationFrameOutput root_output;
  TxEmittedEvent events<kMaxEventsPerTransaction>;
};

/// Complete identification of a unique event within the blockchain.
/// This structure is not constructed during the main transaction workflow; instead,
/// it may be produced by downstream systems (indexers, APIs) that cross-reference
/// events across transactions and blocks.
/// The combination of tx_hash and sequence_number uniquely identifies
/// any event. The sequence_number distinguishes multiple events emitted by
/// the same transaction.
struct IdentifiedEvent {
  TransactionHash tx_hash; // sha256(Transaction)
  BlockHeight block_height;
  unsigned int sequence_number; // uniquifies the event
  TxEmittedEvent emitted_event;
};

} // namespace hogd
