%#include "address_auth.hh"
%#include "catchup.hh"
%#include "network.hh"
%#include "network_config.hh"
%#include "genesis.hh"
%#include "proposal.hh"
%#include "rpc_types.hh"
%#include "types.hh"

namespace hogd {

enum DbSchedResult {
  DbSchedResultOK = 0,
  DbSchedResultError = 1,
  DbSchedResultInvalidParentId = 2
};

const kNativeTokenAgeGroupToSchedule = 0;
const kNativeTokenAgeGroupAlreadyScheduled = 1;
const kNativeTokenAgeGroupReceived = 2;
const kNativeTokenAgeNumGroups = 3;

struct NativeTokenAge {
  ContractAddress address;
  uint128_xdr num_native_tokens[kNativeTokenAgeNumGroups];
  BlockHeight average_ages[kNativeTokenAgeNumGroups];
};

typedef NativeTokenAge NativeTokenAgeBatch<>;

union NativeTokenAgeResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  NativeTokenAge native_token_age;
default:
  void;
};

typedef NativeTokenAgeResult NativeTokenAgeResults<>;

union DbAddressAuthDataBatchResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  AddressAuthData address_auth_data_batch<>;
default:
  void;
};

struct DbBlockOk {
  StorageShortHash storage_hash;
  StorageLongHash storage_long_hash;
  ConfigHashPreimage config_hash_preimage;
};

union DbBlockResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  DbBlockOk block;
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

    NativeTokenAgeResults dbsched_get_native_token_ages(
      ContractAddressBatch) = 2;
    DbSchedResult dbsched_write_native_token_ages(NativeTokenAgeBatch) = 3;

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
    DbBlockResult dbsched_commit_snapshot(BlockID, ConsensusValue) = 6;

    // Call to close a block. This indicates that no more transactions
    // will be added to this block. The block must have been previously opened
    // with open_database_snapshot().
    // A block cannot have a child opened before it is closed.
    // Error if the block has been pruned or contains an item in an invalid
    // state (due to e.g. a block validation failure).
    DbBlockResult dbsched_close_snapshot(BlockID) = 7;

    // Call to abandon a block.
    DbSchedResult dbsched_abandon_snapshot(BlockID) = 8;

    DbSchedResult dbsched_load_genesis_configuration(GenesisConfiguration,
						     ConsensusValue) = 9;

    DbTipResult dbsched_get_tip(void) = 10;

  }
  = 1;
}
= 0x88887ee7;

} // namespace hogd
