
// clang-format off
%#include "types.hh"

namespace hogd
{
// clang-format on

// This struct is serialized and hashed to form the block hash.
struct BlockHeader {
  // A unique identifier for this blockchain. If there are multiple instances of
  // the blockchain running, each one will have a different [network_id].
  unsigned hyper network_id;
  // The height of this block.
  BlockHeight block_height;

  // The Merkle root hash of the transactions.
  SHA256Hash txset_hash;
  // The hash of the database contents after this block is applied to the
  // database.
  DbHash db_hash;
  // The Merkle root hash of the events.
  SHA256Hash events_hash;
  // The hash of the previous block.
  BlockHash prev_block_hash;
};

} // namespace hogd
