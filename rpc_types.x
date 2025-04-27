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
    kRPCNone = 0,
    // Lookup on contract that does not exist in database
    kRPCContractNotExist = 1,
    // Lookup deployment of contract on address that has no deployed contract
    kRPCNoContractDeployed = 2,
    // Executor in bad state to validate or propose
    kRPCBadExecutorState = 3,
    // BlockID does not exist, or is not in correct state
    kRPCBadBlockID = 4,
    // bad storage modification
    kRPCStorageWriteFailed = 5,
    // Requesting an item that doesn't exist
    kRPCNoStorageItem = 6,
    // tx validation or proposal failed
    kRPCTransactionFailed = 7,
    // Some error during validation, beyond just an error in the transaction,
    // such as a nondeterministic RCQ consume not backed by a concurrent insert.
    kRPCValidationFailure = 8,
    // Unimplemented RPC
    kRPCUnimplemented = 9,
  };

  // Flags modifying one Executor->DB storage item RPC
  enum StorageItemRPCFlags {
    kStorageNone = 0,
    // Should the modified item be exclusively locked, in addition to the
    // modification performed.
    kStorageExclusiveLock = 0x00000001
  };

  // XOR of elements in StorageItemRPCFlags
  typedef int StorageItemRPCFlagSet;

  typedef int128_xdr StorageCost;

  union ExpectedStorageCost switch (RPCError error) {
  case kRPCNone:
    StorageCost storage_cost;
  default:
    void;
  };

  // Is this the XDR pattern we want?
  union ExpectedContract switch (RPCError error) {
  case kRPCNone:
    Contract contract;
  default:
    void;
  };

  union ExpectedDeployment switch (RPCError error) {
  case kRPCNone:
    SHA256Hash deployed_hash;
  default:
    void;
  };

  union ExpectedProposalData switch (RPCError error) {
  case kRPCNone:
    NondeterministicProposalData proposal_data;
  default:
    void;
  };

  union ExpectedStorageItem switch (RPCError error) {
  case kRPCNone:
    StorageItem item;
  default:
    void;
  };

} // namespace hogd
