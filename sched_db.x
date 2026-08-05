%#include "network.hh"
%#include "rpc_types.hh"
%#include "types.hh"

namespace hogd {

// A db shard's stable identity: persisted by the shard (hogdb's <SHARDID key)
// and declared to the mempool/executor via ShardCard below, so they bind
// clients by shard_id, not by connection-arrival order. Declared ids must form
// exactly {0..total_shards-1} and every shard must agree on total_shards (= the
// mempool's --num-db-shards).
struct ShardIdentity {
  ExtensionPoint ext;
  unsigned int shard_id;
  unsigned int total_shards;
  // Routing function that produced this shard's data; see sharding.h
  // kShardFunctionId. A mismatch is fail-stop.
  ShardFunction shard_function_id;
};

// ShardCard uniquely describes a database shard instance and its initial
// state.
struct ShardCard {
  ProtocolCommit protocol;
  UPID upid;
  BlockHeight block_height;
  ShardIdentity identity;
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

    void scheddb_hogs_transferred(HogsTransferred) = 2;
  }
  = 1;
}
= 0x7ee79998;

} // namespace hogd
