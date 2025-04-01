namespace hogd {

// A set of types in common RPCs.

// Unique, non-persistent identifier for a block.
// Not the block height.
typedef unsigned hyper BlockID; // uint64_t

// Unique (to one block) identifier of a transaction
typedef unsigned hyper TransactionID; // uint64_t

} // namespace hogd
