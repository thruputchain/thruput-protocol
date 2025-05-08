
// clang-format off
%#include "rpc_types.hh"

namespace hogd {
  // clang-format on

  enum DbResult {
    DbResultOK = 0,
    DbResultError = 1,
  };

  union DbBlockResult switch (DbResult result) {
  case DbResultOK:
    BlockHash block_hash;
  default:
    void;
  };

  program DbCoord
  {
    version DbCoord1
    {

      void dbcoord_null(void) = 0;

      // Examples of valid call sequences to the db:
      //
      // dbcoord_open_snapshot
      //   ... calls to executor
      // dbcoord_commit_snapshot
      //
      // dbcoord_open_snapshot
      //   ... calls to executor
      // dbcoord_close_snapshot
      //
      // dbcoord_open_snapshot
      //   ... calls to executor
      // dbcoord_abandon_snapshot

      // Called when creating a new block.
      // The first argument is the ID of the parent block.
      // The database will surface requests from the snapshot
      // that would be created if the parent block commits.
      // Parent block must be closed.
      DbResult dbcoord_open_snapshot(BlockID, BlockID) = 10;

      // Commits the blockID to disk.  Should only be called for e.g. finalized
      // blocks. At minimum block must be closed before being committed.
      // Any BlockID that is not a descendant of this block will return
      // an error if accessed. This BlockID must be the immediate descendant of
      // the most recently committed block.
      DbBlockResult dbcoord_commit_snapshot(BlockID) = 20;

      // Call to close a block. This indicates that no more transactions
      // will be added to this block. The block must have been previously opened
      // with open_database_snapshot().
      // A block cannot have a child opened before it is closed.
      // Error if the block has been pruned or contains an item in an invalid
      // state (due to e.g. a block validation failure).
      DbBlockResult dbcoord_close_snapshot(BlockID) = 30;

      // Call to abandon a block.
      DbResult dbcoord_abandon_snapshot(BlockID) = 40;
    }
    = 1;
  }
  = 0x7ee78888;

} // namespace hogd
