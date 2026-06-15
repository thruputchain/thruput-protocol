%#include "types.hh"
%#include "retrocausal_queue.hh"
%#include "address_auth.hh"
%#include "transaction.hh"

namespace hogd
{

/// The type of a storage item.
enum StorageItemType {
  kItemTypeBytestring = 0,
  kItemTypeNonnegativeInt = 1,
  kItemTypeRetrocausalQueue = 2,
  kItemTypeReplayCacheData = 3,
  kItemTypeAuthData = 4,
  kItemTypeDeployedContractHash = 5,

  // #[doc(hidden)]
  // This will be removed when we get rid of the old db interface.
  kItemTypeDeleted = -1
};

const kBytestringMaxLen = 1024;
/// An arbitrary value, stored as an opaque string of bytes.
typedef opaque Bytestring<kBytestringMaxLen>;

/// The value at every storage key is one of the following data types.
///
/// [`StorageDelta`]s are modifications that are applied to these StorageItem objects.
///
/// Contracts do not generally directly load these values, but can access them via the typed 
/// system call interface provided by the Groundhog runtime.
/// For example, a contract can call `BytestringGet`, which will return either a Bytestring value or
/// an error if the storage key does not exist or contains a different type.
union StorageItem switch (StorageItemType type)
{
case kItemTypeBytestring:
  /// An arbitrary value, stored as an opaque string of bytes.
  Bytestring bytestring;
case kItemTypeNonnegativeInt:
  /// A nonnegative integer, stored as a 128-bit value.
  ///
  /// This can be stored at any [`StorageKey`] of type `ContractData`.
  /// This type is also used to store the free native token balance at 
  /// storage key `FreeNativeTokenBalance`.
  int128_xdr nnint;
case kItemTypeRetrocausalQueue:
  /// A retrocausal multi-producer, single-consumer queue.
  /// Transactions can only insert entries into the queue or consume entries one by one
  /// from the queue, so the whole queue is generally not loaded all at once.
  QueueEntry queue_entries<>;
case kItemTypeReplayCacheData:
  /// A set of [`Uniquifier`]s that have been used by the current address.
  /// Transactions can only insert a Uniquifier, not read the whole set.
  /// 
  /// This is the type stored at storage key `ReplayCache`.
  /// It cannot be stored at any other storage key.
  Uniquifier active_uniquifiers<>;
case kItemTypeAuthData:
  /// The authorization data for the current address.
  ///
  /// This is the type stored at storage key `AddressAuthData`.
  /// It cannot be stored at any other storage key.
  AddressAuthData auth_data;
case kItemTypeDeployedContractHash:
  /// The hash of the deployed contract for the current address.
  ///
  /// This is the type stored at storage key `AddressMetadata`.
  /// It cannot be stored at any other storage key.
  DeployedContractHash deployed_contract_hash;
};

// #[doc(hidden)]
// This is the type that is actually sent over the network from the database to the executor.
// This type strips out complex types (the replay cache and retrocausal queue) that the
// executor does not need to load.
// The types are filled in, as the executor does need to know the type of an item even 
// without knowing the contents.
union WireStorageItem switch (StorageItemType type) {
case kItemTypeBytestring:
  Bytestring bytestring;
case kItemTypeNonnegativeInt:
  int128_xdr nnint;
case kItemTypeAuthData:
  AddressAuthData auth_data;
case kItemTypeRetrocausalQueue:
  RetrocausalQueueMetadata metadata;
case kItemTypeReplayCacheData:
  void;
case kItemTypeDeployedContractHash:
  DeployedContractHash deployed_contract_hash;
};

/// The types of changes accumulated by a transaction that will be applied to the database
/// if the transaction commits.
enum StorageDeltaType {
  kDeltaTypeBytestringSet = 0,
  kDeltaTypeNonnegativeIntSetAdd = 1,
  kDeltaTypeDelete = 2,
  kDeltaTypeRetrocausalQueue = 3,
  kDeltaTypeNonnegativeIntAdd = 5,
  kDeltaTypeAuthDataChange = 6,
  kDeltaTypeDeployContract = 7,
  kDeltaTypeConsumeUniquifier = 8
};

struct AuthDataChangeSigner {
  unsigned int public_key_id;
  PublicKeyConfigOpt public_key;
};

struct AuthDataChangeArgs {
  AuthDataChangeSigner auth_data_change_signers<>;
  Weight* new_required_weight;
};

struct NonnegativeInt128SetAddArgs {
  int128_xdr set_value;
  int128_xdr add_value;
};

struct ConsumeUniquifierArgs {
  Uniquifier uniquifier;
};

/// One change (of possibly many) accumulated by a transaction to be applied to the database
/// if the transaction commits.
///
/// Each operation (other than `kDeltaTypeDelete`) will create an item of one specific type
/// at the storage key it is applied to.  `kDeltaTypeDelete` will delete the item.
/// These writes overwrite an existing item at the storage key, if any.
/// Two deltas conflict with each other if they would create different types of items
/// at the same storage key (or if one would delete an item that the other would create).
///
/// Beyond that, each subtype of storage delta has its own conflict resolution rules.
union StorageDelta switch (StorageDeltaType type)
{
case kDeltaTypeBytestringSet:
  /// Creates a bytestring item, with the supplied value.
  ///
  /// Item Type: `kItemTypeBytestring`
  ///
  /// Conflicts: 
  ///   - Will conflict with any other delta that creates a *different* item at the same storage key.
  Bytestring bytestring;
case kDeltaTypeNonnegativeIntSetAdd:
  /// Creates a nonnegative integer item.
  /// The value of the int will be equal to the `set_value`, plus the sum of all the `add_value`s supplied
  /// by this delta and all NonnegativeInt128SetAdd and NonnegativeInt128Add deltas in the same block.
  ///
  /// Item Type: `kItemTypeNonnegativeInt`
  ///
  /// Conflicts: 
  ///   - Will conflict with any NonnegativeIntSetAdd delta with a different `set_value`.
  ///   - NonnegativeIntAdd deltas are equivalent to a NonnegativeIntSetAdd delta with a `set_value` equal
  ///     to the value of the item at the start of the block (if it is a nonnegative integer) or 0 otherwise.
  ///     If that implicit set_value is not the same as the supplied `set_value`, the deltas will conflict.
  ///   - At the end of a block, the value will be `set_value` plus the sum of all `add_values` supplied by this
  ///     delta and other deltas from the same block.  Groundhog maintains the property that this expression
  ///     does not overflow a 128-bit integer, and that that value is always at least `min(set_value, 0)`.
  NonnegativeInt128SetAddArgs nnint;
case kDeltaTypeNonnegativeIntAdd:
  /// Adds the supplied value to the nonnegative integer item at the storage key.
  /// This type is equivalent to a NonnegativeIntSetAdd delta with a `set_value` 
  /// equal to the value of the item at the start of the block (if it is a nonnegative integer) or 0 otherwise.
  /// This delta type enables a more efficient implementation of common nonnegative integer use cases (like token balances).
  ///
  /// Item Type: `kItemTypeNonnegativeInt`
  ///
  /// Conflicts: 
  ///   - Same as NonnegativeIntSetAdd deltas.
  int128_xdr nnint_add;
case kDeltaTypeDelete:
  /// Deletes the item at the storage key.
  ///
  /// Item Type: None (deletes the item at the storage key)
  ///
  /// Conflicts: 
  ///   - Will conflict with any other delta that creates a *different* item at the same storage key.
  void;
case kDeltaTypeRetrocausalQueue:
  /// Consumes or inserts entries into the retrocausal queue.
  ///
  /// Item Type: `kItemTypeRetrocausalQueue`
  ///
  /// Conflicts: 
  ///   - Insertions do not conflict with each other.
  ///     TODO(geoff): we may impose limits on the number of entries that can be inserted in one block.
  ///   - Consuming entries conflicts with other consumption deltas in the same block.
  RetrocausalQueueDelta retrocausal_queue;
case kDeltaTypeAuthDataChange:
  /// Changes the authorization data for the current address.
  ///
  /// Item Type: `kItemTypeAuthData`
  ///
  /// Conflicts: 
  ///   - Will conflict with any other auth change delta in the same block.
  AuthDataChangeArgs auth_data_change;
case kDeltaTypeDeployContract:
  /// Deploys a new contract for the current address.
  /// 
  /// Item Type: `kItemTypeDeployedContractHash`
  ///
  /// Conflicts: 
  ///   - None.  The semantics of how contract deployment addresses are calculated (see [`ContractDeploymentHashPreimage`])
  ///     if two transactions deploy a contract to the same address, 
  ///     then both transactions are deploying the exact same contract.
  DeployedContractHash deployed_contract_hash;
case kDeltaTypeConsumeUniquifier:
  /// Add a [`Uniquifier`] to the replay cache.
  ///
  /// Item Type: kItemTypeReplayCacheData 
  ///
  /// Conflicts: 
  ///   - Will conflict with any other attempt to consume the same [`Uniquifier`].
  ConsumeUniquifierArgs consume_uniquifier_args;
};

/// Maximum heights with an unexpired consumed uniquifier in a cache.
const kReplayCacheHeightsMaxLen = 4000;
/// Maximum unexpired consumed uniquifiers allowed per height in a cache.
const kReplayCacheNoncesMaxLen = 8000;

/// Maximum number of entries in a single RetrocausalQueue block.
/// Each entry is at most 256 bytes, so 1000 entries is ~256KB.
const kRetrocausalQueueBlockEntriesMaxLen = 1000;

// #[doc(hidden)]
// Information about the number of nonces stored at each height of a
// ReplayCache. Tracked in the ReplayCacheMetadata so nonce GC can
// determine the change cost after some heights are deleted without
// having to load the nonces at that height.
struct ReplayCacheHeightCount {
  BlockHeight height;
  unsigned int nonce_count;
};

// #[doc(hidden)]
struct ReplayCacheMetadata {
  // Total count of all nonces in this ReplayCache across all heights.
  hyper size;
  // Sorted list of heights with active nonces and count at each.
  ReplayCacheHeightCount heights<kReplayCacheNoncesMaxLen>;
};

// #[doc(hidden)]
struct ReplayCacheData {
  // Sorted list of nonces for a particular height of a ReplayCache.
  unsigned hyper nonces<kReplayCacheNoncesMaxLen>;
};

/// Flags that can be set on a storage delta to modify its behavior.
/// Multiple flags can be combined using bitwise OR.
enum StorageDeltaFlags {
  None = 0,
  /// Forces the delta to acquire an exclusive lock on the item at the storage key,
  /// regardless of any other conflict resolution rules.
  ExclusiveLock = 0x00000001
};

/// A bitset of StorageDeltaFlags values.
typedef int StorageDeltaFlagSet;

/// The combined unit of storage modification sent to the database from the executor.
/// A delta with a set of flags, applied to a specific entry in the database.
struct FlaggedStorageDelta {
  // TODO(geoff): The addrkey field is likely repetitive when sending 
  // many deltas to the database.
  // possibly we can readjust this data structure, if raw bandwidth becomes
  // important.
  AddressAndKey addrkey;
  StorageDelta delta;
  StorageDeltaFlagSet flags;
};

} // namespace hogd
