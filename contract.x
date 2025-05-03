
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

} // namespace hogd
