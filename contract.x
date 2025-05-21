
// clang-format off
%#include "types.hh"

namespace hogd {
  // clang-format on

  typedef opaque ContractBlob<>;

  enum ContractType {
    kWasmi = 0,
    kNative = 1,
    kMockTest = 2,
  };

  union Contract switch (ContractType contract_type)
  {
  case kWasmi:
    ContractBlob wasmi_contract;
  case kNative:
    unsigned int native_contract_id;
  case kMockTest:
    unsigned int mock_contract_id;
  default:
    void;
  };

  struct ContractDeploymentHashPreimage {
    ContractAddress deployer_address;
    SHA256Hash nonce;
    SHA256Hash contract_hash;
  };

  struct ContractInterfaceIDPreimage {
    Identifier interface;
    SemVer interface;
  };

  struct ContractEntrypointID {
    // This field is computed as SHA256(ContractInterfaceIDPreimage)[0..6]
    opaque contract_interface_id[6];
    // The meaning of this field is defined by the contract-interface author
    opaque contract_method_id[2];
  };

  // This type must be a valid "identifier" as defined in RFC 4506,
  // Section 6.2: "An identifier is a letter followed by an optional sequence
  // of letters, digits, or underbar ('_')."  It must also obey Section 6.4,
  // which lists keywords that may not be used as identifiers.
  typedef string Identifier<>;

  // This type must be a valid version number as defined at
  // https://semver.org/.  For example, "0.1.3" or "1.0.0-alpha+001".
  typedef string SemVer<>;

} // namespace hogd
