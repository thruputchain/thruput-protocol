%#include "types.hh"

namespace hogd {

enum AuthClaimType {
  kInvokedAddressSignature = 0,
  kInvokedAddressSignedWeight = 1,
  kOtherAddressSignature = 2,
  kOtherAddressSignedWeight = 3,
};

// between 0 and 31, i.e. 1 byte in CXS encoding
// This is why MAX_SIGNERS <= 31
typedef unsigned int KeyID;

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
