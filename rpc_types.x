namespace hogd {

// A set of types in common RPCs.

// Unique, non-persistent identifier for a block.
// Not the block height.
typedef unsigned hyper BlockID; // uint64_t

// Unique (to one block) identifier of a transaction
typedef unsigned hyper TransactionID; // uint64_t

// This is missing error codes, and is here purely as a placeholder.
// These are some of the error codes I suspect we will need, but these
// are not organized in any particular manner.
//
// TODO(geoff): We may wish to move this to a different file.
enum RPCError {
  kNone = 0,
  // Lookup on contract that does not exist in database
  kContractNotExist = 1,
  // Lookup deployment of contract on address that has no deployed contract
  kNoContractDeployed = 2,
  // BlockID does not exist, or is not in correct state
  kBadBlockID = 3,
  // Requesting an item that doesn't exist
  kNoStorageItem = 4,
};

} // namespace hogd
