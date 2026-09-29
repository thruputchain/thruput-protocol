%#include "network.hh"
%#include "scp.hh"
%#include "types.hh"

namespace hogd {

typedef opaque ValidatorID[32]; // #[rust(newtype)]

typedef PublicKey ValidatorPublicKey;
typedef SecretKey ValidatorSecretKey;

struct ValidatorPublicInfo {
  ValidatorPublicKey public_key;
  ServerAddress address;
};

struct ValidatorPrivateInfo {
  ValidatorPublicInfo public_info;
  ValidatorSecretKey secret_key;
};

} // namespace hogd
