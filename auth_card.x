%#include "network.hh"
%#include "types.hh"

namespace hogd {

struct AuthCard {
  ProtocolCommit protocol;
  UPID upid;
  ServerAddress address_for_db;
  ServerAddress address_for_mempool;
};

} // namespace hogd
