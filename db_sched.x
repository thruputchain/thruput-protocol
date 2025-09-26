// clang-format off
%#include "account.hh"
%#include "rpc_types.hh"
%#include "types.hh"
%#include "catchup.hh"
%#include "nomination.hh"
%#include "genesis.hh"
%#include "rpc_types.hh"

namespace hogd {
// clang-format on

enum DbSchedResult {
  DbSchedResultOK = 0,
  DbSchedResultError = 1
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
  HogAgeBatch hog_age_batch;
default:
  void;
};

union DbAccountAuthDataBatchResult switch (DbSchedResult result)
{
case DbSchedResultOK:
  AccountAuthData account_auth_data_batch<>;
default:
  void;
};

enum DbResult {                                   
  DbResultOK = 0,                                 
  DbResultError = 1                               
};                                                
                                                  
union DbBlockResult switch (DbResult result)      
{                                                 
case DbResultOK:                                  
  BlockHash block_hash;                           
default:                                          
  void;                                           
};                                                
                                                  
union DbCatchupResult switch (DbResult result)    
{                                                 
case DbResultOK:                                  
  CatchupBlock catchup_block;                     
default:                                          
  void;                                           
};                                                
                                                  
struct DbTip {                                    
  BlockHeight height;                             
  BlockHash hash;                                 
  BlockID id;                                     
};                                                
                                                  
union DbTipResult switch (DbResult result)        
{                                                 
case DbResultOK:                                  
  DbTip db_tip;                                   
default:                                          
  void;                                           
};                                                
                                                  
enum DbShardResult {                              
  ShardOK = 0                                     
};                                                

program DbSched
{
  version DbSched1
  {
    void dbsched_null(void) = 0;

    DbAccountAuthDataBatchResult dbsched_get_account_auth_data(
      BlockID, ContractAddressBatch) = 10;

    HogAgeResult dbsched_get_hog_ages(ContractAddressBatch) = 20;
    DbSchedResult dbsched_write_hog_ages(HogAgeBatch) = 30;
                                                                           
// Returns information about the current highest committed block.          
// If there is no committed block, returns DbResultError.                  
    DbTipResult dbcoord_get_tip(void) = 1;                                     
                                                                           
// Examples of valid call sequences to the db:                             
//                                                                         
// dbcoord_create_snapshot | dbcoord_open_snapshot                         
//   ... calls to executor                                                 
// dbcoord_commit_snapshot                                                 
//                                                                         
// dbcoord_create_snapshot | dbcoord_open_snapshot                         
//   ... calls to executor                                                 
// dbcoord_close_snapshot                                                  
//                                                                         
// dbcoord_create_snapshot | dbcoord_open_snapshot                         
//   ... calls to executor                                                 
// dbcoord_abandon_snapshot                                                
                                                                           
// Called when creating a new block.                                       
// The first argument is the ID of the parent block.                       
// The database will surface requests from the snapshot                    
// that would be created if the parent block commits.                      
// Parent block must be closed.                                            
    DbResult dbcoord_create_snapshot(BlockID, BlockID, BlockExecutionMode) =   
    10;                                                                        
                                                                           
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
                                                                   
    DbCatchupResult dbcoord_catchup(BlockHeight) = 50;                
                                                                   
    // Load genesis block data into storage                           
    // This calculates storage keys and stores allocation amounts as  
    // bytestrings                                                    
    DbResult dbcoord_load_genesis_block(GenesisBlock) = 80;           
                                                                   
    // shard_restore blocks until restoration completes.              
    DbShardResult dbcoord_shard_restore(BlockHeight) = 90;            
  }
  = 1;
}
= 0x88887ee7;

} // namespace hogd
