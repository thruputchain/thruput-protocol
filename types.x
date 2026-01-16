namespace hogd {

/// Encodes a 128-bit unsigned integer as two 64-bit unsigned integers.
/// Under the standard XDR encoding, this type serializes as a big-endian u128.
struct uint128_xdr {
  unsigned hyper highbits;
  unsigned hyper lowbits;
};

/// Encodes a 128-bit signed integer as two 64-bit signed integers.
/// Under the standard XDR encoding, this type serializes as a big-endian i128.
struct int128_xdr {
  hyper highbits;
  unsigned hyper lowbits;
};

/// uint64_t, Unix time as nanoseconds elapsed since
/// January 1, 1970 UTC
typedef unsigned hyper TimePoint;

/// Typedef representing a length of memory in bytes, within
/// a wasm runtime.  This is primarily used as an argument to syscalls,
/// and should not be directly used by most contracts.
typedef unsigned int RuntimeMemoryLength; // uint32_t

// TODO(geoff): consider using a smaller type for GasAmount
/// Represents a quantity of gas.  Alias of u64.
typedef unsigned hyper GasAmount; // uint64_t

/// Represents a 512-bit Ed25519 signature.
typedef opaque Ed25519Signature[64]; // #[rust(newtype)]
/// Represents a 256-bit Ed25519 public key.
typedef opaque Ed25519PublicKey[32]; // #[rust(newtype)]
/// Represents a 64-byte Ed25519 secret key.
typedef opaque Ed25519SecretKey[64]; // #[rust(newtype)]

/// Represents the cryptographic scheme used for a signature or public key.
enum CryptographicScheme {
  Ed25519 = 0,
};


/// Union of a Signature type over the various cryptographic schemes.
union Signature switch (CryptographicScheme scheme)
{
case Ed25519:
  Ed25519Signature ed25519;
};

/// Union of a PublicKey type over the various cryptographic schemes.
union PublicKey switch (CryptographicScheme scheme)
{
case Ed25519:
  Ed25519PublicKey ed25519;
};

/// Union of a SecretKey type over the various cryptographic schemes.
union SecretKey switch (CryptographicScheme scheme)
{
case Ed25519:
  Ed25519SecretKey ed25519;
};

/// An ExtensionPoint is a struct that can be embedded as the first
/// element of other XDR structs in order to allow future upgradeability
/// without breaking serialization of pre-existing objects.
/// This serializes as a 32-bit integer.  In its current state,
/// the only valid byte value is 0, but a struct that embeds this can
/// later replace itself with a union (with the prior struct as variant 0)
/// without breaking backwards compatibility.
union ExtensionPoint switch (int v)
{
case 0:
  void;
};

/// Represents a 256-bit SHA-256 hash.
typedef opaque SHA256Hash[32]; // #[rust(newtype)]

/// Represents a 256-bit contract address.
/// In the groundhog storage model, each contract is deployed at a 
/// 32-byte unique `ContractAddress`.
typedef opaque ContractAddress[32]; // #[rust(newtype)]

/// Each ContractAddress owns a namespace of storage keys.
///
/// Most of the keyspace is made up of ContractData keys, which are indexed
/// by 32-byte (arbitrary) identifiers (the `StorageKeyContractData` type).
/// The other variants here have special purposes, and cannot be freely accessed
/// by contracts.
///
/// Contracts are free to set their own conventions for indexing data within
/// the StorageKeyContractData subspace.
enum StorageKeyType {
  /// Contract-controlled data.
  ///
  /// Stores arbitrary data managed by the contract at this address.
  kStorageKeyTypeContractData = 0,

  /// Native token balance.
  ///
  /// Stores the free balance of the native HOG token for this address.
  kStorageKeyTypeFreeNativeTokenBalance = 1,

  /// Address authorization data.
  ///
  /// Stores [`AddressAuthData`] - the authorization configuration including
  /// public keys, weights, gas permissions, and nonce rules.
  kStorageKeyTypeAddressAuthData = 2,

  /// Address metadata.
  ///
  /// Stores [`AddressMetadata`] - metadata about the contract deployed at
  /// this address (hash, size, type).
  kStorageKeyTypeAddressMetadata = 3,

  /// Replay cache for nonce tracking.
  ///
  /// Stores a set of active [`Uniquifier`] objects
  /// to prevent transaction replay attacks.
  kStorageKeyTypeReplayCache = 4,
};

/// Represents an arbitrary 32-byte key into contract storage.
/// This is the key type that contracts directly manipulate
typedef opaque StorageKeyContractData[32]; // #[rust(newtype)]

/// Union of a StorageKey type over the various storage key types.
union StorageKey switch (StorageKeyType key_type)
{
case kStorageKeyTypeContractData:
  StorageKeyContractData contract_data_key;
case kStorageKeyTypeFreeNativeTokenBalance:
  void;
case kStorageKeyTypeAddressAuthData:
  void;
case kStorageKeyTypeAddressMetadata:
  void;
case kStorageKeyTypeReplayCache:
  void;
  // TODO(geoff): add other key types
};


const kTotalHogSupply = 62'500'000'000; // #[rust(const=u64)]
const kHogDivisibility = 10'000'000;    // #[rust(const=u32)]
// Each hog token is divisible into 10^7 units

/// In the global storage, every item is indexed by a unique [contract address + storage key] pair.
struct AddressAndKey {
  ContractAddress address;
  StorageKey key;
};

/// BlockHeight is the height of a block, measured as the number of blocks since the genesis of the chain.
/// The first block of transactions is at height 1.
/// It is signed to prevent overflows in
/// calculations.
typedef hyper BlockHeight;

} // namespace hogd
