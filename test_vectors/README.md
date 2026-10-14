# Test vectors

## pubkey_auth.json

Cross-language vectors for standalone-pubkey accounts (`kPubkeySignature`
auth claims) with Ed25519 and ML-DSA-65 keys, as specified in `types.x`,
`auth_claim.x`, `preimage.x` and `transaction.x`. Each binding and SDK should
reproduce every byte string in it, and its verifier should accept the
`signing` and `resigning` vectors and reject the `negative` ones.

### How it is made and checked

- `gen/` (Go 1.27, standard library only) generates the file:
  `cd gen && go run . -o ../pubkey_auth.json`. It writes XDR and CXS by hand
  and signs with `crypto/ed25519` and `crypto/mldsa`. Its output is
  deterministic. The one random input, the hedged ML-DSA signature of the
  re-signing vector, is made once and pinned in
  `gen/testdata/hedged_signature.hex`.
- `check_vectors.py` re-checks the file independently: its own XDR reader,
  CXS encoder and model of the claim checks, with keys and signatures from
  pyca/cryptography (OpenSSL). It needs `cryptography` 47 or later.
  `python3 check_vectors.py`
- `mldsa_native_oracle.c` serves ML-DSA-65 from mldsa-native v2.0.0, the
  library hogd verifies with (`hogd/external/mldsa-native`).
  `python3 check_vectors.py --mldsa-native ./mldsa_native_oracle` also
  checks every ML-DSA public key, deterministic signature and verification
  result against it. Build instructions are at the top of the file.

So every Ed25519 value is checked by Go and OpenSSL, and every ML-DSA-65
value by Go, OpenSSL and mldsa-native. The encodings follow hogd's code, not
a reading of the `.x` files alone:

| What | hogd source |
| --- | --- |
| CXS | `x23/x23/serialize_cxs.h` |
| `DomainSeparator`, pubkey account address | `hogd/crypto/domain_separators.h` |
| Signing preimage | `hogd/auth_claim/signature_preimage.h` |
| Transaction hash, `sha256(xdr(Transaction))` | `sha256(const T&)` in `hogd/crypto/crypto.h` |
| Devnode bootstrap keys | `hogd/devnode/bootstrap_accounts.cc` |
| Pubkey claim checks and error codes | `hogd/auth_claim/verify.cc` |
| Default wallet `execute` entrypoint | `hogd/hog_exec/runtime/default_wallet_parity_test.cc` |

### Encodings in brief

- **CXS** (canonical, compact). An unsigned integer `v` takes one byte when
  `v <= 62`. Otherwise it is a header byte `0x3f`, `0x7f`, `0xbf` or `0xff`
  followed by 1, 2, 4 or 8 little-endian bytes, always the shortest that
  fits. Enums and union discriminants are their integer value. `opaque[N]`
  is its raw bytes, with no length or padding. `opaque<>` is a CXS length
  followed by the bytes. A struct is its fields in order; a union is its
  discriminant followed by its arm.
- **XDR** is RFC 4506: big-endian, with every item padded to a multiple of
  4 bytes. An `MlDsa65Signature` (3309 bytes) therefore takes 3312 bytes on
  the wire: the signature, then 3 zero bytes.
- `cxs(DomainSeparator(name))` = `00` (the `ExtensionPoint` discriminant 0,
  which has no arm) ‖ CXS length ‖ UTF-8 name. For example
  `cxs(DomainSeparator("PublicKey"))` = `00 09 "PublicKey"`.
- `cxs(PublicKey)` = scheme byte (`00` Ed25519, `01` ML-DSA-65) ‖ raw key.
- `PublicKeyHash` = `sha256(cxs(DomainSeparator("PublicKey")) ‖ cxs(PublicKey))`.
- `cxs(PubkeyAccountPreimage)` = 32-byte `PublicKeyHash` ‖ CXS `nonce`.
  Nonce 0 is `00`; 1 is `01`; 2^64−1 is `ff` followed by eight `ff` bytes.
- address = `sha256(cxs(DomainSeparator("PubkeyAccount")) ‖ cxs(PubkeyAccountPreimage))`.
- signing preimage = `cxs(DomainSeparator("Transaction"))` ‖ 32-byte network
  hash ‖ `xdr(Transaction)`. The signature covers these bytes directly, with
  no further hashing. ML-DSA-65 is pure ML-DSA (not HashML-DSA) with an empty
  context string, so FIPS 204 signs `00 00` ‖ preimage.
- transaction hash = `sha256(xdr(Transaction))`: the unsigned transaction,
  without the network hash or domain separator, and without the signatures
  or `pubkey_claim_key`.

There is no StrKey for contract addresses (C…) in hogd or thruput-go, so the
file has none. G and S StrKeys are Ed25519-only and do not apply here.

### Fields

All byte strings are lowercase hex. Integers that can exceed 2^53 (nonces,
gas, heights) are decimal strings.

**Top level**

- `_comment`: provenance; the file is generated, so don't edit it by hand.
- `format_version`: `1`. It changes whenever the layout of this file does.
- `domain_separators.{PublicKey,PubkeyAccount,Transaction}`: `name` and
  `cxs`, which is `cxs(DomainSeparator(name))`.
- `networks`: 32-byte network hashes. `devnode` is all zeros, hogd's
  `kDefaultRuntimeNetworkHash` and `kDefaultHostedDevnetNetworkHash`. `test`
  is `sha256("thruput-protocol test vectors network")`. `other` is
  `sha256("thruput-protocol test vectors other network")`, used only to sign
  the wrong-network negatives.
- `constants.kDefaultNewAddressKeyID`: `0`. A pubkey claim's single
  signature must carry this `public_key_id`.
- `constants.default_wallet_execute_entrypoint`: the default wallet's
  `execute` entrypoint, the first 8 bytes of
  `sha256("DefaultWallet::0.1::execute")` (method id `0xc3edb11fdd6d5d58`).
- `constants.native_token_address`: `genesis_contract_address(kAddressNativeToken)`.
- `constants.erc20_transfer_entrypoint`: the native token's `transfer`
  entrypoint, the first 8 bytes of `sha256("ERC20::0.1::transfer")`. hogd's
  `contract_trait_test.cc` pins it as `0x63285b3523f9dc3f`.

**`keys[]`**: two Ed25519 keys and two ML-DSA-65 keys.

- `name`: the identifier other entries refer to the key by.
- `scheme`, `scheme_value`: `Ed25519`/`0` or `MlDsa65`/`1`.
- `seed`: 32 bytes. For Ed25519 it is the RFC 8032 private key seed; for
  ML-DSA-65 it is the FIPS 204 key generation seed ξ (`ML-DSA.KeyGen_internal`).
- `seed_derivation`: where the seed comes from. `ed25519_devnode_bootstrap_0`
  is the devnode's bootstrap account 0,
  `sha256("groundhog-dev-accounts:account-0")`. Its public key matches the
  one pinned in hogd's `hog_devnode_test.cc`. `ed25519_rfc8032_test1` is
  RFC 8032 TEST 1. The ML-DSA seeds are `00 01 … 1f` and `ff fe … e0`.
- `public_key`: raw key, 32 or 1952 bytes.
- `public_key_cxs`: `cxs(PublicKey)`.
- `public_key_xdr`: `xdr(PublicKey)`, the form `pubkey_claim_key` takes in a
  `SignedTransaction`.
- `public_key_hash`: `PublicKeyHash`.
- `accounts[]`: for nonces `"0"`, `"1"` and `"18446744073709551615"`:
  `nonce`, `pubkey_account_preimage_cxs` and the 32-byte `address`.

**`signing[]`**: valid end-to-end vectors, each a default wallet `execute`
sent from the key's nonce-0 account. There are two kinds:

- `sign_<key>`: one per key, with a single placeholder call (see
  `wallet_calls` below).
- `transfer_<key>`: two native token transfers on the devnode network.
  Bootstrap account 0 (which a devnode with bootstrap accounts funds with
  1,000,000,000 raw HOG units) sends 100,000,000 to the nonce-0 account of
  `mldsa65_seed_00..1f`, and that account sends 1,000 back. Submit them in
  that order: the second spends what the first sends. Their uniquifiers
  (nonce 101 and 102, expiry height 1000) only work below height 1000.

Fields:

- `name`, `description`, `key`: the vector's name, what it does, and the
  key's name.
- `network`, `network_hash`: which network the transaction is signed for.
  The first key of each scheme uses `devnode` (all zeros); the second uses
  `test`.
- `transaction`: the decoded fields of the unsigned `Transaction`:
  `invoked_address` (the account's address), `entrypoint`, `gas_limit`,
  `calldata`, `block_expiry_height`, `uniquifier_nonce`, `auth_claim_type`
  (`kPubkeySignature`), `pubkey_hash` and `account_nonce`. The claim's
  `PubkeyAccountPreimage` is `{pubkey_hash, account_nonce}`.
  `contracts_to_deploy` is always empty. `calldata` is the CXS encoding of
  `execute(calls: Vec<WalletCall>)`: a CXS count, then for each call its
  `target` (32 bytes), `entrypoint` (8 bytes), CXS `gas_limit`, and CXS
  length-prefixed `calldata`.
- `transaction.wallet_calls[]`: those calls, decoded: `target`,
  `entrypoint`, `gas_limit` and `calldata`.
  - In the `sign_` vectors the call is a placeholder: target the native
    token, entrypoint all zeros, `gas_limit` 100000, empty calldata. Auth is
    checked before execution, so nothing in those vectors depends on it.
  - In the `transfer_` vectors the call is the native token's
    `transfer(receiver, amount)`, with `gas_limit` 1000000, and `transfer`
    holds its `receiver` and `amount` (decimal). The calldata is `receiver`
    (32 bytes) followed by the ERC20 `Amount`, an i128. That travels as the
    CXS tuple (int64 high bits, uint64 low bits), as hogd's `make_amount`
    builds it. For 1000 that is `00 7f e8 03`. A signed CXS integer from −31
    to 31 is one byte, a negative `v` as `0x20 | (~(−v) & 0x1f)`; beyond
    that, it is the unsigned headers followed by the shortest two's
    complement little-endian form.
- `transaction_xdr`: `xdr(Transaction)`.
- `signing_preimage`: the exact bytes signed.
- `transaction_hash`: `sha256(transaction_xdr)`.
- `signature`: the raw signature. Ed25519 signatures are deterministic.
  ML-DSA-65 signatures are deterministic too (FIPS 204 `rnd` = 32 zero
  bytes), so any conforming deterministic signer reproduces them.
- `signature_kind`: a description of the above.
- `signed_transaction_xdr`: `xdr(SignedTransaction)` with one
  `DecoratedSignature` (`public_key_id` 0) and `pubkey_claim_key` set to the
  key.
- `signed_transaction_sha256`: a checksum of `signed_transaction_xdr`, for
  quick comparison.

**`resigning[]`**: shows that re-signing does not change the transaction hash.

- `of`: the `signing` vector it re-signs.
- `signature`, `signature_kind`: a second valid ML-DSA-65 signature over the
  same preimage, made with random `rnd` (hedged).
- `signed_transaction_xdr`: the re-signed transaction. It differs from the
  base vector's, and both are valid.
- `transaction_hash`: equal to the base vector's.

**`negative[]`**: each vector breaks one rule of a valid `signing` vector.

- `name`, `description`: what was changed.
- `base`: the `signing` vector it was derived from.
- `network`, `network_hash`: the network to verify on.
- `signed_transaction_xdr`: the full transaction as submitted.
- `transaction_hash`: `sha256` of its `Transaction` part.
- `expected.result`: always `reject`.
- `expected.error_code`: the `AuthVerifyErrorCode` (`auth_claim.x`):
  `1` is `kAuthMalformed`, a structural error found without checking a
  signature; `2` is `kSignatureVerificationFailed`, a well-formed claim whose
  signature does not verify.
- `expected.reason`: the code's name and the rule that was broken.

The negatives cover, for both schemes: a key/hash mismatch (another key of
the same scheme attached), a missing `pubkey_claim_key`, an altered claim
nonce (alone, and together with the invoked address), a wrong-network
signature, two signatures, a wrong key id, a flipped signature bit, and a
`pubkey_claim_key` on a `kSourceAddressAuthData` claim. They also cover three
scheme mismatches and three ML-DSA-only cases: an all-`ff` signature, an
out-of-range hint count, and a signature with a non-empty context string.

For scheme mismatches, the same bytes cannot be relabeled with the other
scheme tag, because the arms have different lengths. Since `PublicKeyHash`
includes the scheme byte, the hashes would differ anyway. The mismatch
vectors instead pair a key of one scheme with a signature of the other, or
attach a key of the other scheme.

When a vector breaks more than one check, the code is the same whichever
check fails first. The order of the checks is therefore not part of these
vectors. The expected codes follow hogd's current `verify.cc` conventions
extended to the `pubkey_claim_key` rules of `transaction.x`; hogd's
admission wiring for the new rules is still in progress. In particular,
`extra_key_source_claim_*` expects `kAuthMalformed`, on the view that a
stray `pubkey_claim_key` is a structural error found before any
`AddressAuthData` lookup.
