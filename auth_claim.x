%#include "types.hh"

namespace hogd {

//==============================================================================
// Authentication Claims
//
// This module defines the authorization model for Groundhog transactions.
// Each transaction includes a set of AuthClaims that specify which signatures
// are required to authorize the transaction's execution.
//
// Workflow:
// 1. A user constructs a Transaction, which includes some number of AuthClaims.
// 2. Signatures are added to create a SignedTransaction
// 3. Groundhog verifies that signatures match the auth claims (before execution)
// 4. During execution, contracts can read the auth claims but NOT the signatures
//
// This design ensures transaction behavior depends only on the auth claims
// (which are included in what gets signed), not on the signature bytes themselves.
// This makes transactions signature-scheme agnostic and prevents signature
// reordering or re-randomization from changing transaction behavior.
//
// The authentication model supports two claim types:
// - Weighted bitmap: the transaction carries a bitmap of which keys signed,
//   and the account stores per-key weights and a minimum threshold
// - Pubkey signature: a standalone public key signs the transaction
//
// Auth claims reference AddressAuthData stored at each contract address,
// which defines the available keys and their weights.
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
typedef unsigned int BitMap;

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

/// Maximum number of auth claims allowed in a single transaction.
///
/// This limits the verification complexity of a transaction.
const kMaxAuthClaims = 10;

//------------------------------------------------------------------------------
// Auth Claim Types
//------------------------------------------------------------------------------

/// Discriminator for the different types of authorization claims.
enum AuthClaimType {
  /// Requires a weighted threshold of signatures from the source address.
  ///
  /// The bitmap specifies which keys signed the transaction, and the
  /// account's per-key weights are accumulated and compared against
  /// `required_weight` stored in the account's AddressAuthData.
  kSourceAddressSignedWeight = 0,

  /// Requires a signature from a specific public key.
  ///
  /// Used for accounts identified by a pubkey preimage (pubkey + nonce).
  kPubkeySignature = 1
};

struct PubkeyAccountPreimage {
  PublicKey pubkey;
  unsigned hyper nonce;
};

/// An authorization claim specifying what signatures are needed to authorize
/// a transaction.
///
/// Each transaction includes one or more auth claims. During verification,
/// the signatures in the `SignedTransaction` are matched against these claims
/// to determine if the transaction is properly authorized.
union AuthClaim switch (AuthClaimType claim_type) {
case kSourceAddressSignedWeight:
  /// Bitmap of keys that signed the transaction.
  /// Bit `i` = 1 means key `i` from the source address's key set signed.
  /// The accumulated weight of the signing keys must meet the account's
  /// `required_weight` threshold.
  BitMap accepted_keys;

case kPubkeySignature:
  PubkeyAccountPreimage pubkey_preimage;
};

/// A list of auth claims for a transaction.
///
/// Each transaction must include at least one auth claim to be valid.
/// The list is bounded by `kMaxAuthClaims` to limit verification complexity.
typedef AuthClaim AuthClaimData<kMaxAuthClaims>;

//------------------------------------------------------------------------------
// Auth Verification Error Codes
//------------------------------------------------------------------------------

/// Error codes returned when verifying authorization on a SignedTransaction.
///
/// There are three levels of verification:
/// 1. Well-formedness: basic structural checks (e.g., key IDs are in range)
/// 2. Claims validity: signatures match claimed keys and weights are satisfied
/// 3. Signature verification: cryptographic validation of all signatures
///
/// These error codes distinguish between different failure modes to enable
/// appropriate handling at different stages of transaction processing.
enum AuthVerifyErrorCode {
  /// The transaction's auth claims are malformed.
  ///
  /// Transactions with this error should never be flooded over the network
  /// as they are structurally invalid. Examples include:
  /// - Public key IDs that are out of bounds
  /// - Invalid bitmaps (bits set beyond kMaxSigners)
  /// - Mismatched signature counts
  kAuthMalformed = 1,

  /// Cryptographic signature verification failed.
  ///
  /// This indicates that one or more signatures did not pass cryptographic
  /// validation against the claimed public keys. The transaction structure
  /// is valid but the signatures themselves are incorrect.
  kSignatureVerificationFailed = 2,

  /// Mismatch between auth claims and actual auth data on an account.
  ///
  /// This indicates that the transaction references keys or permissions
  /// that do not exist or do not satisfy the requirements. Examples include:
  /// - Referencing a public key ID that doesn't exist in the auth data
  /// - Failing to meet required weight thresholds
  kAuthDataMismatch = 3
};

} // namespace hogd
