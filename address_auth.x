% #include "types.hh"
% #include "contract.hh"
% #include "auth_claim.hh"

namespace hogd
{

//==============================================================================
// Address Authorization Data
//
// This module defines the authorization configuration stored at each address.
// In Groundhog, every address can originate transactions and can be configured
// with multiple signing keys, weighted multi-signature requirements, and
// gas sponsorship permissions.
//
// Unlike Ethereum's model which distinguishes between externally-owned
// addresses (EOAs) and contract addresses, Groundhog treats every address
// uniformly: all addresses are contracts and can have sophisticated
// authorization logic.
//==============================================================================

//------------------------------------------------------------------------------
// Public Key Configuration
//------------------------------------------------------------------------------

/// Configuration for a single public key registered to an address.
/// Each address can have up to kMaxSigners public keys, each with an
/// associated weight for multi-signature authorization.
struct PublicKeyConfig {
  /// The public key (supports multiple cryptographic schemes via union).
  PublicKey key;
  /// The weight of this key in multi-signature calculations.
  /// When verifying weighted auth claims, weights from signing keys
  /// are accumulated and compared against the required threshold.
  Weight max_weight;
};

/// Optional PublicKeyConfig, used in the public_keys array.
/// A null value indicates that key slot is unoccupied.
typedef PublicKeyConfig *PublicKeyConfigOpt;  // #[rust(newtype)]

//------------------------------------------------------------------------------
// Gas Permission Configuration
//------------------------------------------------------------------------------

/// Configuration for gas sponsorship permissions.
/// Allows an address to grant specific keys permission to spend gas
/// on behalf of the address, with configurable limits and multi-sig requirements.
struct GasPermissionConfig {
  /// Maximum amount of gas that can be spent under this permission.
  GasAmount limit;
  /// Bitmap of keys that are acceptable for this gas permission.
  BitMap accepted_keys;
  /// Total weight required from the accepted keys to use this permission.
  Weight required_weight;
};

//------------------------------------------------------------------------------
// Nonce Configuration
//------------------------------------------------------------------------------

/// Configuration for transaction nonce management.
/// Specifies which keys can increment the nonce and what weight is required.
struct NonceConfig {
  /// Bitmap of keys that can contribute to nonce operations.
  BitMap accepted_keys;
  /// Total weight required to increment the nonce.
  Weight required_weight;
};

//------------------------------------------------------------------------------
// Default Initialization Values
//------------------------------------------------------------------------------

/// Default required weight for a newly initialized address.
/// When an address is first created (e.g., from a public key hash),
/// the auth data is initialized with these defaults.
const kDefaultNewAddressRequiredWeight = 1;

/// Default accepted keys bitmap for a newly initialized address.
/// 0xFFFFFFFF means all key slots are initially acceptable.
const kDefaultNewAddressAcceptedKeys = 0xFFFFFFFF;

/// Default key ID for the initial key of a newly initialized address.
/// The public key used to derive the address is installed as key 0.
const kDefaultNewAddressKeyID = 0;

//------------------------------------------------------------------------------
// Address Authorization Data
//------------------------------------------------------------------------------

/// The complete authorization configuration for an address.
///
/// This struct stores all the information needed to verify transactions
/// originating from an address:
/// - The set of public keys and their weights
/// - Gas sponsorship permissions
/// - Nonce management rules
///
/// When a transaction is submitted, its AuthClaims are verified against
/// this data to determine if the transaction is properly authorized.
///
/// TODO(geoff) and TODO(dobog): The initialization workflow (when upgrading
/// an address from just a pk to a full contract) should explicitly set the
/// auth data with sensible defaults, so that the default is NOT to accidentally
/// lock the address.
struct AddressAuthData {
  /// Array of up to kMaxSigners public keys.
  /// Null entries indicate unoccupied key slots.
  PublicKeyConfigOpt public_keys[kMaxSigners];

  /// Gas permission configurations.
  /// Allows separation of concerns (e.g., sponsored gas vs contract owner management).
  GasPermissionConfig gas_permissions<kMaxGasConfigs>;

  /// Configuration for nonce management.
  NonceConfig nonce_config;

  /// The block height at which this auth data was last modified.
  /// TODO(geoff): this can be removed once hogdb has a way to track this directly
  /// on each db item.
  BlockHeight last_written_height;
};

//------------------------------------------------------------------------------
// Deployed Contract Metadata
//------------------------------------------------------------------------------

/// Hash and metadata for a contract deployed at an address.
/// This allows the system to locate and instantiate the contract code
/// without loading the full contract from storage.
struct DeployedContractHash {
  /// SHA-256 hash of the deployed contract code.
  SHA256Hash hash;

  /// Size of the contract in bytes.
  /// This field is technically redundant, but allows computing and updating
  /// storage costs without reloading the entire contract from storage.
  unsigned int contract_size;

  /// The type of contract (e.g., Wasm, native, etc.).
  /// Used as an annotation hint in the executor to determine which type of
  /// runtime to instantiate. Redundant with the stored contract, but allows
  /// avoiding loading the whole contract from storage.
  ContractType contract_type;
};

/// Metadata associated with an address.
/// Currently only stores information about the deployed contract, if any.
struct AddressMetadata {
  /// Information about the contract deployed at this address.
  DeployedContractHash deployed_contract;
};

} // namespace hogd
