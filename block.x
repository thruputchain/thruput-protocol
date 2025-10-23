
// clang-format off
%#include "types.hh"

namespace hogd
{
// clang-format on

// This struct is serialized and hashed to form the block hash.
struct BlockHashPreimage {
  SHA256Hash txs_merkle_trie_root_hash;
  BlockHash prev_block_hash;
};

} // namespace hogd
