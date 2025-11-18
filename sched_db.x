// clang-format off
%#include "rpc_types.hh"
%#include "types.hh"
namespace hogd {
// clang-format on

// ShardCard uniquely describes a database shard instance and its initial
// state.
struct ShardCard {
  Protocol protocol;
  UPID upid;
  BlockHeight block_height;
  // This is the db address that the executor should connect to.
  ServerAddress address_for_exec;
  // This is the db address that the scheduler should connect to.
  ServerAddress address_for_sched;
};

struct Delta {
  ContractAddress address;
  int128_xdr hog_delta;
};

struct HogsTransferred {
  // The height of the block in which these transfers occurred. The scheduler
  // uses this height to update average hog ages.
  BlockHeight block;
  Delta deltas<>;
};

program SchedDb
{
  version SchedDb1
  {
    // [scheddb_intro_shard] is called by a db shard to introduce itself to the
    // system.
    void scheddb_intro_shard(ShardCard) = 1;

    void scheddb_hogs_transferred(BlockHeight, HogsTransferred) = 2;

    // Notify the scheduler of which accounts have changed their auth data,
    // so that the scheduler can invalidate cached auth checks.
    void scheddb_changed_accounts(BlockHeight, ContractAddressBatch) = 3;
  }
  = 1;
}
= 0x7ee79998;

} // namespace hogd
