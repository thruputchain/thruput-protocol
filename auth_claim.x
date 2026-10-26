%#include "types.hh"

namespace hogd {

//==============================================================================
// Authentication Claims
//
// This module defines the authorization model for Thruput transactions.
// Each transaction includes an AuthClaim that specifies which signatures
// are required to authorize the transaction's execution.
//
// Workflow:
// 1. A user constructs a Transaction, which includes an AuthClaim.
// 2. Signatures are added to create a SignedTransaction
// 3. Thruput verifies that signatures match the AuthClaim (before execution)
// 4. During execution, contracts can read the AuthClaim and relevant compressed metadata,
// (such as which keys were used to authorize the transaction), but not the actual signatures.
//
// This design ensures transaction behavior depends only on the AuthClaim
// (which are included in what gets signed), not on the signature bytes themselves.
// This makes transactions signature-scheme agnostic and prevents signature
// reordering or re-randomization from changing transaction behavior.
//
// The authentication model supports two claim types:
// - Source address auth data: the transaction is signed by the keys in the source address's auth data.
//   and the account stores per-key weights and a minimum threshold
// - Pubkey signature: a standalone public key signs the transaction. The claim
//   names the key by its hash; the key itself is attached to the signatures.
//
// Source address claims reference AddressAuthData stored at the source
// address, which defines the available keys and their weights. Pubkey claims
// are for addresses with no AddressAuthData.
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
/// Only bits below `kMaxSigners` may be set; a bitmap with a higher bit set
/// is `kAuthMalformed`.
typedef unsigned int BitMap;

/// Identifier for a public key within an address's key set.
///
/// Valid range is 0 to `kMaxSigners - 1` (0-20).
typedef unsigned int KeyID;

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------

/// Maximum number of signers that can be configured on an address.
///
/// This matches Stellar's `MAX_SIGNERS` (20) plus 1 for the primary key.
/// Must be <= 32 so that every key ID has a bit in a [`BitMap`].
const kMaxSigners = 21; // #[rust(const=u32)]

//------------------------------------------------------------------------------
// Auth Claim Types
//------------------------------------------------------------------------------

/// Discriminator for the different types of authorization claims.
enum AuthClaimType {
  /// Requires a set of signatures from the source address's auth data.
  /// The runtime checks whether the signing keys' weights sum to at least the
  /// larger of the auth data's required weight and the claim's own
  /// `required_weight`.
  // TODO: consider surfacing the data about which keys signed in a syscall.
  kSourceAddressAuthData = 0,

  /// Requires a signature from a specific public key.
  ///
  /// Used for accounts identified by a pubkey preimage (pubkey hash + nonce).
  kPubkeySignature = 1
};

/// The preimage of a standalone-pubkey account's address:
/// `sha256(cxs(DomainSeparator("PubkeyAccount")) || cxs(PubkeyAccountPreimage))`.
///
/// It names the key by its [`PublicKeyHash`] rather than holding the key, so
/// that the auth claim contracts read stays small whatever the scheme. The
/// key itself travels with the signatures, as
/// [`SignedTransaction::pubkey_claim_key`] in transaction.x.
struct PubkeyAccountPreimage {
  PublicKeyHash pubkey_hash;
  unsigned hyper nonce;
};

/// An authorization claim specifying what signatures are needed to authorize
/// a transaction.
union AuthClaim switch (AuthClaimType claim_type) {
case kSourceAddressAuthData:
  /// The transaction is signed by the keys in the source address's auth data.
  /// The bitmap specifies which are allowed to be used to sign the transaction,
  /// and the signatures must be listed in strictly increasing `public_key_id`
  /// order. `required_weight` can only raise the auth data's threshold: the
  /// signing weight must reach the larger of the two.
  struct {
    BitMap allowed_keys;
    Weight required_weight;
  } source_address_claim;

case kPubkeySignature:
  PubkeyAccountPreimage pubkey_preimage;
};

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
