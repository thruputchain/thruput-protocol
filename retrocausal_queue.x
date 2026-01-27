// clang-format off
%#include "types.hh"

namespace hogd {
// clang-format on

const kQueueEntryMaxLen = 256;
typedef opaque QueueEntry<kQueueEntryMaxLen>; // #[rust(newtype)]

// A block in a retrocausal queue, containing a list of entries and a block
// number The entries are stored in lexicographically sorted order within the
// block Block numbers are monotonically increasing
struct RetrocausalQueueBlock {
  QueueEntry entries<>; // Variable-length array of queue entries
  unsigned hyper
  block_number; // Unique identifier and ordering for this block
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
  QueueEntry current_block_consumed<>;
};

struct RetrocausalQueueInsertDelta {
  QueueEntry added_entries<>;
};

struct RetrocausalQueueDelta {
  // set to null if no entries are consumed.
  // This version of the retrocausal queue is single-consumer multi-producer.
  RetrocausalQueueConsumeDelta *consume;
  RetrocausalQueueInsertDelta insert;
};
}
