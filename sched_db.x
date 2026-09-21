%#include "network.hh"
%#include "rpc_types.hh"
%#include "types.hh"

namespace hogd {

// ShardCard uniquely describes a database shard instance and its initial
// state.
struct ShardCard {
  ProtocolCommit protocol;
  UPID upid;
  BlockHeight block_height;
  // This is the db address that the executor should connect to.
  ServerAddress address_for_exec;
  // This is the db address that the scheduler should connect to.
  ServerAddress address_for_sched;
  // This is the db address that the auth server should connect to.
  ServerAddress address_for_auth;
};

struct Delta {
  ContractAddress address;
  int128_xdr hog_delta;
};

// One slice of the native-token balance deltas a committed block finalized.
//
// hog_db publishes a block's deltas as a run of chunk_count chunks, all for
// the same block, after the block is committed. hog_db chooses the chunk
// size; the wire bounds a chunk only by the link's record cap. The chunks of
// a run may be sent concurrently and over several connections, so they can
// arrive in any order; hog_db starts the next block's run only after every
// chunk of this one is acknowledged, so the mempool never has more than one
// block's run in flight. An address appears in at most one chunk of a block's
// run (a shard holds one balance per address) and every delta is nonzero. The
// mempool treats the block's transfers as complete only once every chunk of
// the run has arrived; nothing that gates on a block's transfers may open
// before that.
struct HogsTransferredChunk {
  // The height of the block in which these transfers occurred. The scheduler
  // uses this height to update average hog ages.
  BlockHeight block;
  // This chunk's position in the block's run, from 0, and the run's length.
  // Every chunk of a run carries the same chunk_count, and each index in
  // [0, chunk_count) is sent exactly once. A block that finalized no nonzero
  // delta is a run of one empty chunk, so every committed block still sends
  // a run.
  unsigned int chunk_index;
  unsigned int chunk_count;
  Delta deltas<>;
};

program SchedDb
{
  version SchedDb1
  {
    // [scheddb_intro_shard] is called by a db shard to introduce itself to the
    // system.
    void scheddb_intro_shard(ShardCard) = 1;

    // Retired numbers, never to be reused, so that a peer built against one
    // fails to dispatch rather than misparse a newer payload:
    //   2: scheddb_hogs_transferred(HogsTransferred), a block's deltas in one
    //      unbounded record, which a block with enough distinct recipients
    //      grows past any single-record cap (hogd#2332).
    //   3: scheddb_changed_addresses(BlockHeight, ContractAddressBatch),
    //      removed in e413dc9. Its payload also opens with a block height and
    //      a vector length, so a chunk sent on 3 would decode there as
    //      addresses.

    // Deliver one chunk of a committed block's balance deltas. With several db
    // shards the mempool completes the block once every registered shard has
    // sent its run's last chunk.
    void scheddb_hogs_transferred_chunk(HogsTransferredChunk) = 4;
  }
  = 1;
}
= 0x7ee79998;

} // namespace hogd
