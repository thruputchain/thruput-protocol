// clang-format off
%#include "types.hh"

namespace hogd {
// clang-format on

const kQueueEntryMaxLen = 256;
typedef opaque QueueEntry<kQueueEntryMaxLen>; // #[rust(newtype)]

/// Per-transaction cap on the number of concurrent RetrocausalQueue entries a
/// transaction may observe (peek/consume) and record in its
/// NondeterministicProposalData. Each observation is proposer-controlled and
/// must be buffered and validated against an insert, so an unbounded count is
/// an unbounded memory/compute vector — this is a tx resource limit in the same
/// family as gas, not an RPC artifact. Because it is a tx-observable count
/// checked against this protocol constant, the limit is consensus-uniform
/// (every node agrees on "<= cap reads") and independent of any RPC buffer size.
/// (Full rationale — incl. why an RPC-message-size bound would be unsafe — in
/// the PR.)
const kMaxConcurrentRcqReadsPerTx = 16384;

/// Maximum number of entries in a single RetrocausalQueue block.
/// Each entry is at most 256 bytes. With XDR serialization overhead (4 bytes
/// per entry length prefix, 12 bytes framing), ramdb key overhead (73 bytes),
/// and ItemHeader (24 bytes), 250 entries of 256 bytes fits within ramdb's
/// 64 KiB item limit (kBigItemThreshold). See issue #1437.
const kRetrocausalQueueBlockEntriesMaxLen = 250;

// A block in a retrocausal queue, containing a list of entries and a block
// number The entries are stored in lexicographically sorted order within the
// block Block numbers are monotonically increasing
struct RetrocausalQueueBlock {
  QueueEntry entries<>; // Variable-length array of queue entries
  unsigned hyper block_number; // Unique identifier and ordering for this block
};

// This delta consumes all of the retrocausal queue entries
// in blocks less than or equal to max_fully_consumed_block_number,
// and removes the first partial_consumed_number entries from the
// block number max_fully_consumed_block_number + 1.
struct RetrocausalQueuePastBlockConsumeDelta {
  unsigned hyper max_fully_consumed_block_number;
  unsigned hyper partial_consumed_number;
};

// Root metadata for a Retrocausal Queue, stored at the item key.
// Tracks both head (consume state) and tail (production state).
struct RetrocausalQueueMetadata {
  // Current consume state - where consumption left off.
  RetrocausalQueuePastBlockConsumeDelta consume_state;

  // The highest block number currently live (written and not fully consumed).
  // New blocks will be numbered max_live_block_num + 1.
  // 0 if no blocks have been produced yet.
  unsigned hyper max_live_block_num;

  // Total number of entries currently live in the queue (for cost calculation).
  unsigned hyper live_entries;
};

struct RetrocausalQueueConsumeDelta {
  RetrocausalQueuePastBlockConsumeDelta past_block_consume;
  QueueEntry current_block_consumed<kRetrocausalQueueBlockEntriesMaxLen>;
};

struct RetrocausalQueueInsertDelta {
  QueueEntry added_entries<kRetrocausalQueueBlockEntriesMaxLen>;
};

struct RetrocausalQueueDelta {
  // set to null if no entries are consumed.
  // This version of the retrocausal queue is single-consumer multi-producer.
  RetrocausalQueueConsumeDelta *consume;
  RetrocausalQueueInsertDelta insert;
  // Concurrent entries observed (e.g. via peek) but not consumed.
  // HogDb validates that each entry was actually inserted by a concurrent
  // transaction. Unlike current_block_consumed, these do not decrement the
  // insert balance — they only require that a matching insert exists.
  //
  // This is bounded by the per-transaction observation cap
  // (kMaxConcurrentRcqReadsPerTx), not the much smaller per-block entry cap
  // (kRetrocausalQueueBlockEntriesMaxLen), for a non-obvious reason: when a
  // validator replays a proposed block, the executor rebuilds this per-queue
  // array from the proposer-supplied observation list, and a dishonest proposer
  // can pack a whole transaction's observations into a single queue. The bogus
  // entries are caught afterward (HogDb matches each observed entry to a real
  // insert), but the array must be built before that check runs -- so it has to
  // hold a full transaction's worth. Capping it at the per-block size would make
  // that rebuild overflow and crash the validator instead of cleanly rejecting.
  QueueEntry observed_concurrent_entries<kMaxConcurrentRcqReadsPerTx>;
  // Set when the transaction deleted or overwrote the key before using it as
  // a queue, so the queue starts empty and every past-block entry of a
  // committed queue at the key is consumed. The executor leaves the past-block
  // position to HogDb, which knows the committed queue: consume, if present,
  // must carry a zero past_block_consume, and HogDb resolves it to cover the
  // whole committed queue. A committed queue with live entries makes this
  // delta the block's consumer, exactly as if consume were set.
  bool replace;
};
}
