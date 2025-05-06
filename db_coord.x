
// clang-format off
%#include "rpc_types.hh"

namespace hogd {
  // clang-format on

  program DbCoord
  {
    version DbCoord1
    {

      void dbcoord_null(void) = 0;

      // Called when creating a new block.
      // The first argument is the ID of the parent block.
      // The database will surface requests from the snapshot
      // that would be created if the parent block commits.
      // Parent block must be closed.
      RPCError dbcoord_open_snapshot(BlockID, BlockID) = 10;

      // Commits the blockID to disk.  Should only be called for e.g. finalized
      // blocks. At minimum block must be closed before being committed.
      // Any BlockID that is not a descendant of this block will return
      // an error if accessed. This BlockID must be the immediate descendant of
      // the most recently committed block.
      RPCError dbcoord_commit_snapshot(BlockID) = 20;

      // Call to close a block. This indicates that no more transactions
      // will be added to this block. The block must have been previously opened
      // with open_database_snapshot().
      // A block cannot have a child opened before it is closed.
      // Error if the block has been pruned or contains an item in an invalid
      // state (due to e.g. a block validation failure).
      RPCError dbcoord_close_snapshot(BlockID) = 30;
    }
    = 1;
  }
  = 0x7ee78888;

} // namespace hogd
