// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]
typedef SHA256Hash ConsensusBasisHash; // #[rust(newtype)]

// The small consensus value: the block header. Serialized and hashed to form
// the ConsensusValueHash that identifies the block.
struct ConsensusValue {
  // A unique identifier for this blockchain. If there are multiple instances
  // of the blockchain running, each one will have a different [network_id].
  unsigned hyper network_id;
  // The height of this block.
  BlockHeight block_height;
  TimePoint timestamp;
  ValidatorID proposer;
  Upgrade upgrades<6>;
  // The Merkle root hash of the transactions.
  SHA256Hash txset_hash;
  // The hash of the database contents after this block is applied to the
  // database.
  DbHash db_hash;
  // The Merkle root hash of the events.
  SHA256Hash events_hash;
  // The hash of this block's ConsensusBasis.
  ConsensusBasisHash basis_hash;
  // The hash of the previous block's ConsensusValue.
  ConsensusValueHash prev_value_hash;
};

// The big data behind a ConsensusValue; serialized and hashed to form the
// ConsensusBasisHash.
struct ConsensusBasis {
  Nomination nomination;
};

typedef ConsensusBasis *OptConsensusBasis;

// The big consensus value: a full block. Contains all of the fields of the
// small value (ConsensusValue) up front, so the XDR serialization of a
// ConsensusValueWithBasis begins with the XDR serialization of its
// ConsensusValue.
struct ConsensusValueWithBasis {
  ConsensusValue value;
  ConsensusBasis basis;
};

} // namespace hogd
