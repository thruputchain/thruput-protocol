// clang-format off

%#include "types.hh"
%#include "contract.hh"
%#include "transaction.hh"
%#include "storage_item.hh"
%#include "address_auth.hh"

namespace hogd
{
// clang-format on

// An internal unique ID describing a block.
typedef unsigned hyper BlockID;

// XXX(petar): BlockHash should be renamed to MerkleHash
typedef SHA256Hash BlockHash;

struct DbTip {
  BlockHeight height;
  BlockHash hash;
  BlockID id;
};

// Internal unique ID describing a transaction.
// Can be reused across blocks but cannot be reused within one block.
typedef unsigned hyper TransactionID;

// This is missing error codes, and is here purely as a placeholder.
// These are some of the error codes I suspect we will need, but these
// are not organized in any particular manner.
//
// TODO(geoff): This probably should get moved to a different file?
enum RPCError {
  kRPCNone = 0,
  // Lookup on an item in the database that does not exist.
  // Used by any database lookup RPC, not just for one type.
  kRPCNotFound = 1,
  // BlockID does not exist, or is not in correct state
  kRPCBadBlockID = 3,
  // bad storage modification
  kRPCStorageWriteFailed = 4,
  // tx validation or proposal failed
  kRPCTransactionFailed = 5,
  // Unimplemented RPC
  kRPCUnimplemented = 6,
  // Unrecoverable error in the server (i.e. OOM, DB corruption)
  kRPCUnrecoverable = 7
};

// The mode in which a block executes.
enum BlockExecutionMode {
  kBlockExecutionModeValidation = 0,
  kBlockExecutionModeProposal = 1
};

typedef int128_xdr StorageCost;

union ExpectedStorageCost switch (RPCError error)
{
case kRPCNone:
  StorageCost storage_cost;
default:
  void;
};

// Is this the XDR pattern we want?
union ExpectedContract switch (RPCError error)
{
case kRPCNone:
  Contract contract;
default:
  void;
};

union ExpectedDeployment switch (RPCError error)
{
case kRPCNone:
  DeployedContractHash deployed_hash;
default:
  void;
};

union ExpectedProposalData switch (RPCError error)
{
case kRPCNone:
  NondeterministicProposalData proposal_data;
default:
  void;
};

union ExpectedStorageItem switch (RPCError error)
{
case kRPCNone:
  WireStorageItem item;
default:
  void;
};

union ExpectedRetrocausalQueueBlock switch (RPCError error)
{
case kRPCNone:
  RetrocausalQueueBlock queue_block;
default:
  void;
};

union ExpectedQueueEntry switch (RPCError error)
{
case kRPCNone:
  QueueEntry queue_entry;
default:
  void;
};

union ExpectedDBTip switch (RPCError error)
{
case kRPCNone:
  DbTip db_tip;
default:
  void;
};

/// Typedef for a list of contract addresses.
typedef ContractAddress ContractAddressBatch<>;

} // namespace hogd
