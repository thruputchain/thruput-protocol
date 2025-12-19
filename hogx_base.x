// clang-format off
namespace hogx {
// clang-format on

typedef hyper Timestamp;

typedef string Path<>;
typedef string Tag<>;
typedef string Flag<>;

struct StringMap {
  string key<>;
  string value<>;
};

struct PortMap {
  string key<>;
  int port;
};

struct AddressMap {
  string key<>;
  int address;
};

} // namespace hogx
