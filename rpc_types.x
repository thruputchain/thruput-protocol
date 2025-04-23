// clang-format off

%#include "types.hh"
%#include "contract.hh"
%#include "transaction.hh"
%#include "storage_item.hh"

namespace hogd
{
  // clang-format on

  // An internal unique ID describing a block.
  typedef unsigned hyper BlockID;
  // Internal unique ID describing a transaction.
  // Can be reused across blocks but cannot be reused within one block.
  typedef unsigned hyper TransactionID;

  // This is missing error codes, and is here purely as a placeholder.
  // These are some of the error codes I suspect we will need, but these
  // are not organized in any particular manner.
  //
  // TODO(geoff): This probably should get moved to a different file?
  enum RPCError {
    kNone = 0,
    // Lookup on contract that does not exist in database
    kContractNotExist = 1,
    // Lookup deployment of contract on address that has no deployed contract
    kNoContractDeployed = 2,
    // Executor in bad state to validate or propose
    kBadExecutorState = 3,
    // BlockID does not exist, or is not in correct state
    kBadBlockID = 4,
    // bad storage modification
    kStorageWriteFailed = 5,
    // Requesting an item that doesn't exist
    kNoStorageItem = 6,
    // tx validation or proposal failed
    kTransactionFailed = 7,
    // Some error during validation, beyond just an error in the transaction,
    // such as a nondeterministic RCQ consume not backed by a concurrent insert.
    kValidationFailure = 8,
  };

  // Flags modifying one Executor->DB storage item RPC
  enum StorageItemRPCFlags {
    kNone = 0,
    // Set if the item is to be included in the final commitment
    // of a transaction (as opposed to a reservation within a try_invoke block).
    kFinalCommit = 0x00000001,
    // Should the modified item be exclusively locked, in addition to the
    // modification performed.
    kExclusiveLock = 0x00000002
  };

  // XOR of elements in StorageItemRPCFlags
  typedef int StorageItemRPCFlagSet;

  typedef int128_xdr StorageCost;

  union ExpectedStorageCost switch (RPCError error) {
  case kNone:
    StorageCost storage_cost;
  default:
    void;
  };

  // Is this the XDR pattern we want?
  union ExpectedContract switch (RPCError error) {
  case kNone:
    Contract contract;
  default:
    void;
  };

  union ExpectedDeployment switch (RPCError error) {
  case kNone:
    SHA256Hash deployed_hash;
  default:
    void;
  };

  union ExpectedProposalData switch (RPCError error) {
  case kNone:
    NondeterministicProposal proposal_data;
  default:
    void;
  };

  union ExpectedStorageItem switch (RPCError error) {
  case kNone:
    StorageItem item;
  default:
    void;
  };

} // namespace hogd
