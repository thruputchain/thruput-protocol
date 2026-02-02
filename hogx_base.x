// clang-format off
namespace hogx {
// clang-format on

// TODO: x23c does not allow an empty struct, it requires "void;" inside, whereas
// goxdr does not allow a "void;" field.
struct Void {
  int *xxx;
};

typedef hyper Timestamp;

typedef string Path<>;
typedef string Tag<>;
typedef string Flag<>;

struct KeyString {
  string key<>;
  string value<>;
};
typedef KeyString StringMap<>;

struct KeySocketAddress {
  string key<>;
  string address<>; // ip4 or ip6 + port
};
typedef KeySocketAddress SocketAddressMap<>;

struct File {
  Path path;
  string content<>;
};
typedef File Files<>;

} // namespace hogx
