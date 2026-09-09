%#include "types.hh"

namespace hogd {

const kAuthTokenMaxLen = 256; // #[rust(const=u32)]
/// Levels of node nesting a token may carry when a configuration does not
/// state `kConfigParamMaxAuthTokenDepth`. Consensus-critical, so frozen.
const kAuthTokenMaxDepth = 4; // #[rust(const=u32)]
const kAuthTokenMaxChildNodes = 4; // #[rust(const=u32)]

typedef opaque AuthTokenPayload<kAuthTokenMaxLen>; // #[rust(newtype)]

struct AuthTokenNode {
  ContractAddress consumer_address;
  AuthTokenPayload payload;
  AuthTokenNode child_nodes<kAuthTokenMaxChildNodes>;
};

struct AuthToken {
  ContractAddress mint_address;
  BlockHeight expiry_height;
  AuthTokenNode root_node;
};

} // namespace hogd
