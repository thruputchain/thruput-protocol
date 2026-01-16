%#include "network.hh"
%#include "types.hh"

namespace hogd {

struct AuthCard {
  Protocol protocol;
  UPID upid;
  ServerAddress address_for_db;
  ServerAddress address_for_mempool;
};

} // namespace hogd
