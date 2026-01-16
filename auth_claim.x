%#include "types.hh"

namespace hogd {

typedef unsigned int Weight; // uint32_t
typedef unsigned hyper BitMap;

// If we use the bitmap approach, should be less than the width of
// the bitmap.
// This constant is intended to match the MAX_SIGNERS constant in the Stellar protocol,
// which is 20.  We add 1 to account for the primary key on a Stellar account.
const kMaxSigners = 21; // #[rust(const=u32)]
// Could be 1; Slightly useful to have multiple for sponsored gas,
// i.e. separating sponsor ops vs contract owner management
const kMaxGasConfigs = 5; // #[rust(const=u32)]

// between 0 and 31, i.e. 1 byte in CXS encoding
// This is why MAX_SIGNERS <= 31
typedef unsigned int KeyID;

enum AuthClaimType {
  kInvokedAddressSignature = 0,
  kInvokedAddressSignedWeight = 1,
  kOtherAddressSignature = 2,
  kOtherAddressSignedWeight = 3,
};

union AuthClaim switch (AuthClaimType claim_type) {
case kInvokedAddressSignature:
  KeyID invoked_address_signature_id;
case kInvokedAddressSignedWeight:
  struct {
    BitMap accepted_keys;
    Weight required_weight;
  } invoked_address_signed_weight;
case kOtherAddressSignature:
  struct {
    ContractAddress address;
    KeyID key_id;
  } other_address_signature_id;
case kOtherAddressSignedWeight:
  struct {
    ContractAddress address;
    BitMap accepted_keys;
    Weight required_weight;
  } other_address_signed_weight;
};

const kMaxAuthClaims = 10;

typedef AuthClaim AuthClaimData<kMaxAuthClaims>;

} // namespace hogd
