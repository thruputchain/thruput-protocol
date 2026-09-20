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

// Most deltas one HogsTransferredChunk carries. A Delta encodes to 48 bytes,
// so a full chunk holds 12 MiB of deltas: under x23's 16 MiB default record
// cap with room for the call header, and a bounded allocation on the receiver
// where the whole block used to be one record. Enforced at decode; hog_db may
// send smaller chunks.
const kMaxDeltasPerHogsTransferredChunk = 262144;

// One slice of the native-token balance deltas a committed block finalized.
//
// hog_db publishes a block's deltas as a run of chunks followed by exactly one
// HogsTransferredDone, all for the same block, after the block is committed.
// A shard sends the run one call at a time, awaiting each reply, so it arrives
// in order and the mempool never has a whole block outstanding. An address
// appears in at most one chunk of a block's run (a shard holds one balance per
// address) and every delta is nonzero. The mempool applies each chunk as it
// arrives and treats the block's transfers as complete only at the done
// message; nothing that gates on a block's transfers may open on a chunk.
struct HogsTransferredChunk {
  // The height of the block in which these transfers occurred. The scheduler
  // uses this height to update average hog ages.
  BlockHeight block;
  Delta deltas<kMaxDeltasPerHogsTransferredChunk>;
};

// Ends a block's run of HogsTransferredChunk. Sent once per block per shard,
// after the shard's last chunk for that block, for every committed block,
// including one that finalized no nonzero delta (chunk_count 0). The counts
// let the receiver check the run it applied against the run the shard sent
// before it opens the block's transfer gate; a mismatch is fail-stop, since a
// block whose deltas are only partly applied cannot be scheduled against.
struct HogsTransferredDone {
  BlockHeight block;
  // Chunks the shard sent for this block.
  unsigned int chunk_count;
  // Deltas across those chunks.
  unsigned hyper delta_count;
};

program SchedDb
{
  version SchedDb1
  {
    // [scheddb_intro_shard] is called by a db shard to introduce itself to the
    // system.
    void scheddb_intro_shard(ShardCard) = 1;

    // Procedure 2 was scheddb_hogs_transferred(HogsTransferred): a block's
    // deltas in one unbounded record, which a block with enough distinct
    // recipients grows past any single-record cap (hogd#2332). Retired, not
    // reused, so a peer built against it fails to dispatch rather than
    // misparse.

    // Deliver one chunk of a committed block's balance deltas.
    void scheddb_hogs_transferred_chunk(HogsTransferredChunk) = 3;

    // Close a committed block's run of chunks. With several db shards the
    // mempool completes the block once every registered shard has sent this.
    void scheddb_hogs_transferred_done(HogsTransferredDone) = 4;
  }
  = 1;
}
= 0x7ee79998;

} // namespace hogd
