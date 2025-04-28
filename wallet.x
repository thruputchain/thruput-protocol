namespace hogd {

struct WalletUser {
  string name<>;
  SHA256Hash password_hash;
};

} // namespace hogd
