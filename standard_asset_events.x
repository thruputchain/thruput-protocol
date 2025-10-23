%#include "types.hh"

namespace hogd {

// number of topics is 3:
// 1. event signature
// 2. from_address
// 3. to_address
struct TransferEvent {
  ContractAddress from_address;
  ContractAddress to_address;
  int128_xdr amount;
};

struct ApprovalEvent {
  ContractAddress owner_address;
  ContractAddress spender_address;
  int128_xdr amount;
};

} // namespace hogd
