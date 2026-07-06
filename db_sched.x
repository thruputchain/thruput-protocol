// clang-format off
%#include "address_auth.hh"
%#include "rpc_types.hh"
%#include "types.hh"
%#include "catchup.hh"
%#include "network.hh"
%#include "proposal.hh"
%#include "genesis.hh"
%#include "rpc_types.hh"

namespace hogd {
// clang-format on

enum DbSchedResult {
  DbSchedResultOK = 0,
  DbSchedResultError = 1,
  DbSchedResultInvalidParentId = 2
};

const kHogAgeGroupToSchedule = 0;
const kHogAgeGroupAlreadyScheduled = 1;
const kHogAgeGroupReceived = 2;
const kHogAgeNumGroups = 3;

struct HogAge {
  ContractAddress address;
  uint128_xdr num_hogs[kHogAgeNumGroups];
  BlockHeight average_ages[kHogAgeNumGroups];
};

typedef HogAge HogAgeBatch<>;

union HogAgeResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  HogAge hog_age;
default:
  void;
};

typedef HogAgeResult HogAgeResults<>;

union DbAddressAuthDataBatchResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  AddressAuthData address_auth_data_batch<>;
default:
  void;
};

union DbBlockResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  StorageHash storage_hash;
default:
  void;
};

enum DbShardResult {
  ShardOK = 0
};

union DbTipResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  DbTip db_tip;
default:
  void;
};

program DbSched
{
  version DbSched1
  {
    void dbsched_null(void) = 0;

    DbAddressAuthDataBatchResult dbsched_get_address_auth_data(
      BlockID, ContractAddressBatch) = 1;

    HogAgeResults dbsched_get_hog_ages(ContractAddressBatch) = 2;
    DbSchedResult dbsched_write_hog_ages(HogAgeBatch) = 3;

    // Examples of valid call sequences to the db:
    //
    // dbsched_create_snapshot | dbsched_open_snapshot
    //   ... calls to executor
    // dbsched_commit_snapshot
    //
    // dbsched_create_snapshot | dbsched_open_snapshot
    //   ... calls to executor
    // dbsched_close_snapshot
    //
    // dbsched_create_snapshot | dbsched_open_snapshot
    //   ... calls to executor
    // dbsched_abandon_snapshot

    // Called when creating a new block.
    // The first argument is the ID of the parent block.
    // The database will surface requests from the snapshot
    // that would be created if the parent block commits.
    // Parent block must be closed.
    DbSchedResult dbsched_create_snapshot(BlockID, BlockID, BlockExecutionMode)
    = 5;

    // Commits the block with the specified block ID to disk. Should only be
    // called for e.g. finalized blocks. At a minimum, the block must be closed
    // before being committed. Any BlockID that is not a descendant of this
    // block will return an error if accessed. This BlockID must be the
    // immediate descendant of the most recently committed block.
    // XXX: What is the third hash argument? It should be typed by its purpose!
    DbBlockResult dbsched_commit_snapshot(BlockID, ProposalHeaderHash, SHA256Hash) = 6;

    // Call to close a block. This indicates that no more transactions
    // will be added to this block. The block must have been previously opened
    // with open_database_snapshot().
    // A block cannot have a child opened before it is closed.
    // Error if the block has been pruned or contains an item in an invalid
    // state (due to e.g. a block validation failure).
    DbBlockResult dbsched_close_snapshot(BlockID) = 7;

    // Call to abandon a block.
    DbSchedResult dbsched_abandon_snapshot(BlockID) = 8;

    // Load genesis configuration data into storage. The second argument is the
    // network ID. The third argument is the txset hash and the third argument
    // is the events hash. Since the genesis block does not contain any
    // transactions, both of these hashes will generally be the root hash of an
    // empty Merkle trie.
    //
    // This RPC calculates storage keys and stores allocation amounts as
    // bytestrings.
    DbSchedResult dbsched_load_genesis_configuration(GenesisConfiguration,
						     unsigned hyper, SHA256Hash, SHA256Hash) = 9;

    DbTipResult dbsched_get_tip(void) = 10;
  }
  = 1;
}
= 0x88887ee7;

} // namespace hogd
