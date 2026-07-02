// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

// The hash of a BigValue. Distinct from BlockHash (types.x), which is the
// hash of the SmallValue and serves as the block's identifier.
typedef SHA256Hash BigValueHash; // #[rust(newtype)]

// NAMING: "BigValue" and "SmallValue" are deliberate placeholders to defer
// the naming debate. The final names for this pair will be either
// Block/BlockHeader or ConsensusBasis/ConsensusValue.

// The big value: the canonical data on which consensus runs. Serialized and
// hashed to form the BigValueHash. Everything in the SmallValue is derived
// from this struct; the BigValue is authoritative.
struct BigValue {
  TimePoint timestamp;
  ValidatorID proposer;
  Nomination nomination;
  Upgrade upgrades<6>;
  // The hash of the previous block's SmallValue. Present here (rather than
  // only in SmallValue) so that the SmallValue is derivable from the BigValue
  // alone.
  BlockHash prev_small_value_hash;
};

typedef BigValue *OptBigValue;

// The small value: the block header. Serialized and hashed to form the
// BlockHash that identifies the block.
//
// Every field is derived from the BigValue; a SmallValue carries no
// information of its own. It exists so that consumers (light clients, repair,
// indexers) can identify and chain blocks, and verify transaction/event
// Merkle proofs, without holding the multi-kilobyte BigValue.
struct SmallValue {
  // A unique identifier for this blockchain. If there are multiple instances
  // of the blockchain running, each one will have a different [network_id].
  // = nomination.network_id
  unsigned hyper network_id;
  // The height of this block.
  // = nomination.block_height
  BlockHeight block_height;
  // = BigValue.timestamp
  TimePoint timestamp;
  // = BigValue.proposer
  ValidatorID proposer;
  // = BigValue.upgrades
  Upgrade upgrades<6>;
  // The Merkle root hash of the transactions.
  // = nomination.txset_hash
  SHA256Hash txset_hash;
  // The Merkle root hash of the events.
  // = nomination.events_hash
  SHA256Hash events_hash;
  // The commitment to the database contents after this block is applied.
  // = nomination.db_commitment
  DbCommitment db_commitment;
  // The hash of this block's BigValue (the current big value).
  // = sha256(BigValue)
  BigValueHash big_value_hash;
  // The hash of the previous block's SmallValue (the previous small value).
  // The previous BigValue is pinned transitively, via the previous small
  // value's big_value_hash.
  // = BigValue.prev_small_value_hash
  BlockHash prev_small_value_hash;
};

} // namespace hogd
