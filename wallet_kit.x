namespace hogd {

typedef opaque JWTSecretKey<>;

struct WalletUser {
  string login<>;
  SHA256Hash password_hash;
};

}
