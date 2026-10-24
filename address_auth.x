% #include "types.hh"
% #include "contract.hh"
% #include "auth_claim.hh"

namespace hogd
{

//==============================================================================
// Address Authorization Data
//
// This module defines the authorization configuration stored at each address.
// This configuration data tells Groundhog whether or not a given transaction
// can begin execution in a given block.
//
// In Groundhog, every address can originate transactions and can be configured
// with multiple signing keys and weighted multi-signature requirements.
//
// TODO(geoff): give an example of what that might look like here.
//
// Unlike the common blockchain model (as in, for example, Ethereum), in which
// there is an explicit demarcation between so-called "externally owned addresses" (EOAs)
// that can initiate transactions but have no associated code, and "contract addresses",
// which hold invocable code but cannot initiate transactions,
// Groundhog treats every address uniformly: all addresses can both hold a contract
// and initiate a transaction.
//==============================================================================

//------------------------------------------------------------------------------
// Public Key Configuration
//------------------------------------------------------------------------------

/// Configuration for a single public key registered to an address.
///
/// Each address can have up to `kMaxSigners` public keys, each with an
/// associated weight for multi-signature authorization.
struct PublicKeyConfig {
  /// The public key (supports multiple cryptographic schemes via union).
  PublicKey key;

  /// The weight of this key in multi-signature calculations.
  ///
  /// When verifying weighted auth claims, weights from signing keys
  /// are accumulated and compared against the required threshold.
  Weight max_weight;
};

/// Optional `PublicKeyConfig`, used in the `public_keys` array.
///
/// A null value indicates that key slot is unoccupied.
typedef PublicKeyConfig *PublicKeyConfigOpt;  // #[rust(newtype)]

//------------------------------------------------------------------------------
// Default Initialization Values
//------------------------------------------------------------------------------

/// Default required weight for a newly initialized address.
///
/// An address has no [`AddressAuthData`] until a change registers a key or
/// writes a threshold for it. The row that change creates requires this
/// weight unless the change writes a threshold of its own.
const kDefaultNewAddressRequiredWeight = 1;

/// The key ID a `kPubkeySignature` claim's single signature must carry.
///
/// Nothing is installed under it: an address authorized by a pubkey claim has
/// no [`AddressAuthData`] at all.
const kDefaultNewAddressKeyID = 0;

//------------------------------------------------------------------------------
// Address Authorization Data
//------------------------------------------------------------------------------

/// The complete authorization configuration for an address.
///
/// This struct stores all the information needed to verify transactions
/// originating from an address:
/// - The set of public keys and their weights
/// - The minimum weight threshold required to authorize a transaction
///
/// When a transaction is submitted with a `kSourceAddressAuthData`
/// [`AuthClaim`], the claim is verified against this data to determine if the
/// transaction is properly authorized.
///
/// This is the type stored at storage key type `AuthData`.
///
/// # TODO
///
/// (geoff) and (dobog): The initialization workflow (when upgrading
/// an address from just a pk to a full contract) should explicitly set the
/// auth data with sensible defaults, so that the default is NOT to accidentally
/// lock the address.
struct AddressAuthData {
  /// Array of up to `kMaxSigners` public keys.
  ///
  /// Null entries indicate unoccupied key slots.
  PublicKeyConfigOpt public_keys[kMaxSigners];

  /// The minimum total weight required from signing keys to authorize
  /// a transaction from this address.
  Weight required_weight;

  /// The block height at which this auth data was last modified.
  ///
  /// # TODO
  ///
  /// (geoff): this can be removed once hog_db has a way to track this directly
  /// on each db item.
  BlockHeight last_written_height;
};

} // namespace hogd
