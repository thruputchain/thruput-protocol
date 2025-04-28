namespace hogd {

struct WalletUser {
  string login<>;
  SHA256Hash password_hash;
};

} // namespace hogd
