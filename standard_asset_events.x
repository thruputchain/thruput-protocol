%#include "types.hh"

namespace hogd {

// number of topics is 3:
// 1. event signature
// 2. from_address
// 3. to_address
//
// A `from_address` or `to_address` equal to the all-zero `ContractAddress`
// denotes "no address" (a mint or a burn reported as a transfer). That
// address is reserved (see `ContractAddress` in types.x), so nothing can
// ever hold a balance or receive a call there.
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
