%#include "types.hh"

namespace hogd {

struct AuthCard {
  Protocol protocol;
  UPID upid;
  ServerAddress address;
};

} // namespace hogd
