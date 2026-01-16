%#include "types.hh"

namespace hogd {

//==============================================================================
// Authentication Claims
//
// This module defines the authorization model for Groundhog transactions.
// Each transaction includes a set of AuthClaims that specify which signatures
// are required to authorize the transaction's execution.
//
// The authentication model supports:
// - Single-signature authorization (one specific key must sign)
// - Multi-signature authorization (weighted threshold of keys must sign)
// - Cross-contract authorization (signatures from other contract addresses)
//
// Auth claims are verified against AddressAuthData stored at each contract
// address, which defines the available keys and their weights.
//==============================================================================

//------------------------------------------------------------------------------
// Basic Types
//------------------------------------------------------------------------------

/// Represents the weight of a signature key in multi-signature schemes.
///
/// Weights are accumulated from signing keys and compared against a required
/// threshold to determine if an auth claim is satisfied.
typedef unsigned int Weight; // uint32_t

/// A bitmap representing a set of key IDs.
///
/// Each bit position corresponds to a key ID (bit 0 = key 0, bit 1 = key 1, etc.).
/// Used to specify which keys are acceptable for satisfying an auth claim.
typedef unsigned hyper BitMap;

/// Identifier for a public key within an address's key set.
///
/// Valid range is 0-31 (must fit in one byte for CXS encoding).
/// This is why `kMaxSigners` is constrained to be <= 31.
typedef unsigned int KeyID;

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

/// Maximum number of signers that can be configured on an address.
///
/// This matches Stellar's `MAX_SIGNERS` (20) plus 1 for the primary key.
/// Must be <= 31 to fit in the `BitMap` representation.
const kMaxSigners = 21; // #[rust(const=u32)]

/// Maximum number of gas permission configurations per address.
///
/// Multiple configs allow separation of concerns (e.g., sponsored gas vs
/// contract owner management operations).
const kMaxGasConfigs = 5; // #[rust(const=u32)]

/// Maximum number of auth claims allowed in a single transaction.
///
/// This limits the verification complexity of a transaction.
const kMaxAuthClaims = 10;

//------------------------------------------------------------------------------
// Auth Claim Types
//------------------------------------------------------------------------------

/// Discriminator for the different types of authorization claims.
///
/// Claims are categorized by:
/// 1. Whether they reference the invoked contract or another contract
/// 2. Whether they require a single signature or weighted multi-sig
enum AuthClaimType {
  /// Requires a signature from a specific key on the invoked contract address.
  ///
  /// This is the simplest and most common authorization pattern.
  kInvokedAddressSignature = 0,

  /// Requires a weighted threshold of signatures from the invoked contract.
  ///
  /// The bitmap specifies which keys are acceptable, and signatures are
  /// accumulated until the `required_weight` threshold is met.
  kInvokedAddressSignedWeight = 1,

  /// Requires a signature from a specific key on a different contract address.
  ///
  /// Used for cross-contract authorization (e.g., a contract authorizing
  /// operations on behalf of another contract).
  kOtherAddressSignature = 2,

  /// Requires a weighted threshold of signatures from a different contract.
  ///
  /// Combines cross-contract auth with multi-signature requirements.
  kOtherAddressSignedWeight = 3,
};

/// An authorization claim specifying what signatures are needed to authorize
/// a transaction.
///
/// Each transaction includes one or more auth claims. During verification,
/// the signatures in the `SignedTransaction` are matched against these claims
/// to determine if the transaction is properly authorized.
///
/// The four variants support different authorization patterns:
/// - Single key from invoked contract (most common)
/// - Multi-sig from invoked contract (for high-security operations)
/// - Single key from other contract (for delegation)
/// - Multi-sig from other contract (for complex delegated operations)
union AuthClaim switch (AuthClaimType claim_type) {
case kInvokedAddressSignature:
  /// The ID of the key that must sign, from the invoked address's key set.
  KeyID invoked_address_signature_id;

case kInvokedAddressSignedWeight:
  struct {
    /// Bitmap of acceptable keys (bit `i` = 1 means key `i` can contribute).
    BitMap accepted_keys;
    /// Total weight required from the accepted keys' signatures.
    Weight required_weight;
  } invoked_address_signed_weight;

case kOtherAddressSignature:
  struct {
    /// The contract address whose key must sign.
    ContractAddress address;
    /// The ID of the key from that address's key set.
    KeyID key_id;
  } other_address_signature_id;

case kOtherAddressSignedWeight:
  struct {
    /// The contract address whose keys must sign.
    ContractAddress address;
    /// Bitmap of acceptable keys from that address's key set.
    BitMap accepted_keys;
    /// Total weight required from the accepted keys' signatures.
    Weight required_weight;
  } other_address_signed_weight;
};

/// A list of auth claims for a transaction.
///
/// Each transaction must include at least one auth claim to be valid.
/// The list is bounded by `kMaxAuthClaims` to limit verification complexity.
typedef AuthClaim AuthClaimData<kMaxAuthClaims>;

} // namespace hogd
