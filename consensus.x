// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusBasisHash; // #[rust(newtype)]

// The big value: the canonical data on which consensus runs. Serialized and
// hashed to form the ConsensusBasisHash. Everything in the BlockHeader is
// derived from this struct; the ConsensusBasis is authoritative.
struct ConsensusBasis {
  TimePoint timestamp;
  ValidatorID proposer;
  Nomination nomination;
  Upgrade upgrades<6>;
  // The hash of the previous block's BlockHeader. Present here (rather than
  // only in BlockHeader) so that the BlockHeader is derivable from the
  // ConsensusBasis alone.
  BlockHash prev_block_hash;
};

typedef ConsensusBasis *OptConsensusBasis;

// The small value: the block header. Serialized and hashed to form the
// BlockHash that identifies the block.
//
// Every field is derived from the block's ConsensusBasis; a BlockHeader
// carries no information of its own. It exists so that consumers (light
// clients, repair, indexers) can identify and chain blocks, and verify
// transaction/event Merkle proofs, without holding the multi-kilobyte
// ConsensusBasis.
struct BlockHeader {
  // A unique identifier for this blockchain. If there are multiple instances
  // of the blockchain running, each one will have a different [network_id].
  // = nomination.chain_state.network_id
  unsigned hyper network_id;
  // The height of this block.
  // = nomination.chain_state.block_height
  BlockHeight block_height;
  // = ConsensusBasis.timestamp
  TimePoint timestamp;
  // = ConsensusBasis.proposer
  ValidatorID proposer;
  // = ConsensusBasis.upgrades
  Upgrade upgrades<6>;
  // The Merkle root hash of the transactions.
  // = nomination.chain_state.txset_hash
  SHA256Hash txset_hash;
  // The Merkle root hash of the events.
  // = nomination.chain_state.events_hash
  SHA256Hash events_hash;
  // The hash of the database's post-state summary. Stands in for the full
  // ChainState (which contains the 2 KiB DbHash) to keep the header small.
  // = sha256(nomination.chain_state)
  SHA256Hash chain_state_hash;
  // The hash of this block's ConsensusBasis (the current big value).
  // = sha256(ConsensusBasis)
  ConsensusBasisHash basis_hash;
  // The hash of the previous block's BlockHeader (the previous small value).
  // The previous ConsensusBasis is pinned transitively, via the previous
  // header's basis_hash.
  // = ConsensusBasis.prev_block_hash
  BlockHash prev_block_hash;
};

} // namespace hogd
