%#include "types.hh"

namespace hogd {

// #[rust(ConstWriteXDR)]
struct DomainSeparator {
  ExtensionPoint ext;
  opaque domain_separator<256>;
};

// XDR does not have generics.
// The preimage to a signature or hash is as follows:
//
// template<typename T> struct VersionedPreimage {
//    DomainSeparator domain_separator;
//    T object;
//};
//
// For example, the address of a pubkey auth account is derived as follows:
// sha256(cxs(DomainSeparator("PubkeyAccount")) || cxs(PubkeyAccountPreimage))
//
// where PubkeyAccountPreimage names the account's key by its PublicKeyHash:
// sha256(cxs(DomainSeparator("PublicKey")) || cxs(PublicKey))

} // namespace hogd
