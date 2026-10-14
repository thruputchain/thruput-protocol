# Thruput text encoding

Status: target format for the pre-launch base58 migration (GH-502). Consumers
must adopt the corresponding new API/schema version before emitting this format.
This document does not change XDR or CXS serialization.

## Binary identity

Addresses, keys, hashes, signatures, and transaction payloads retain their current
bytes, lengths, and protocol types. Encode those bytes directly, in their existing
order. Do not hash them again, reverse their byte order, or encode their XDR length
prefix. Do not change enum discriminants or account derivation.

`types.x` already distinguishes `ContractAddress`, `Ed25519PublicKey`,
`SHA256Hash`, `PublicKeyHash`, and other binary types. No schema change is needed
just to display them differently. `PublicKey` also supports ML-DSA: only Ed25519
keys have a G representation. Other key schemes remain base58 in Stellar mode.

## Canonical base58

Use the Bitcoin/Solana alphabet, without a checksum or prefix:

```text
123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
```

- Encoding is case-sensitive. Never lowercase or uppercase a base58 value.
- Preserve every leading zero byte as a leading `1`.
- Empty bytes encode as the empty string. A nonempty fixed-size value cannot be
  represented by the empty string.
- Reject whitespace, non-ASCII characters, padding, and characters outside the
  alphabet. User interfaces may trim surrounding whitespace before parsing;
  machine parsers must not.
- Decode to bytes and check the field's exact length or maximum length. A regex
  alone cannot prove a base58 string represents a 32-byte value.
- Check encoded length before allocation/conversion, then decoded length. For
  maximum byte length N > 0, `floor(N * 138 / 100) + 1` is a conservative encoded
  length bound; N = 0 admits only the empty string. Use checked arithmetic.
- No hex fallback. A string that happens to contain only hex characters can
  also be valid base58: decode it only as base58 and enforce the field's byte
  length. Do not reject valid base58 merely because it resembles unprefixed hex.

Use base58 for typed addresses, public keys, hashes, and signatures in RPC,
CLI JSON, dApp/wallet messages, persisted records, and default human output.
Keep opaque payloads in existing `0x`-prefixed lowercase hex. A byte's role,
not the length or contents of a value, determines its encoding. There is no
base58/base64 conversion of bulk payloads in this migration.

## Field classification

| Field or value | Machine encoding | Reason |
| --- | --- | --- |
| Address, public key, validator ID | Base58 | Typed identity |
| Transaction, block, network, config, code, and storage hashes | Base58 | Typed digest, including the 2048-byte `StorageLongHash` |
| Standalone signature | Base58 | Typed cryptographic value |
| Serialized signed transaction or authorization envelope | Hex | Complete opaque binary payload; embedded keys/signatures are not separately recoded |
| Contract code, calldata, return/abort buffers, storage bytes, raw events | Hex | Opaque payload, even if only 32 bytes long |
| Raw event topics and topic filters | Hex | `event.x` defines each topic as an arbitrary leading 32-byte chunk of serialized event data |
| Contract-data storage keys | Hex | `types.x` defines arbitrary 32-byte keys, not a mandatory digest algorithm |
| Diagnostic serialized storage keys | Hex | XDR union payload, not an address or hash |
| Entrypoint/method selectors | Hex | Fixed ABI selector bytes, not a public key or digest field |
| Pagination cursors | Existing hex, passed back verbatim | Opaque server-authored continuation payload |
| Numeric nonces, amounts, counters, and enum tags | Existing numeric format | Not byte strings |
| Serialized nonce/preimage buffers | Hex | Opaque bytes, unless the schema explicitly declares a digest |
| Explicit Ed25519 seed import/export | Base58 or S StrKey | Secret handling is explicit; never ordinary diagnostic output |

Raw topics use one encoding for every slot, including a signature-hash topic or
an indexed address: RPC cannot assume the event schema from its contents. A
schema-aware decoded event field uses its declared type (for example, a decoded
address uses base58), while its raw topic remains hex. Do not convert raw topics
by inspecting their contents or position.

Numbers retain their existing JSON number/decimal-string rules. External
identifiers (Git SHAs, checksums required by external formats) retain their own
formats. Typed values decoded from CXS use their declared semantic type; raw
CXS/XDR buffers remain hex. No binary layouts or hashing inputs change.

Payload limits remain expressed in decoded bytes and must not be reduced as part
of this migration. Hex payload support is canonical, not a compatibility fallback.
Reject old hex only on fields moving to base58. Existing payload parsing behavior
is preserved; tightening hex parsers is outside this migration.

## Stellar input and display

Follow [SEP-23](https://github.com/stellar/stellar-protocol/blob/master/ecosystem/sep-0023.md).
StrKey is uppercase, unpadded base32 of the version byte, payload, and a
little-endian CRC16-XModem checksum. Validate the full version, checksum, length,
and canonical encoding, not just the leading character.

| Value | Default / machine format | Stellar human display |
| --- | --- | --- |
| Thruput address (including wallets and tokens) | Base58 | C StrKey |
| Ed25519 public key | Base58 | G StrKey |
| Other public-key schemes | Base58 | Base58 |
| Any hash or standalone signature | Base58 | Base58 |
| Opaque payload, raw topic, storage key, selector, or cursor | Hex | Hex |
| Ed25519 seed, explicitly exported | Base58 | Explicit S export supported |

Only human-facing typed parsers accept StrKey in addition to base58. Machine
fields retain the base58/hex split above. A G key is not a wallet address; C/G conversion must not
derive accounts. A 32-byte byte array is not automatically a key or address.
T and X are signer types, not transaction-hash display formats.

Actual Stellar destinations use their native G/C/M representation and an
explicit network/type context. StrKey itself contains no network identity. M
includes an unsigned 64-bit routing ID: preserve it or reject unsupported use,
never truncate it to G. This format work does not enable a new bridge route.

## Shared vectors and generated bindings

`fixtures/text-encoding.json` contains public byte arrays and expected encodings.
Use it unchanged in each language's tests. `scripts/text_encoding_vectors.py`
checks it with an independent integer-based base58 and stdlib CRC/base32 oracle.
The script also checks published Stellar vectors; it is not a production codec.
The base58 cases test the codec itself, including empty and arbitrary bytes;
they do not imply all byte fields use base58. Each vector also supplies its
canonical hex payload representation so consumers can test both boundaries.

## Verification

The agent runs unit, mock-RPC, schema, formatting, type, and build checks. Adam
runs real-node integration and smoke tests locally: this cloud-agent has not
reliably reached devnode readiness. Supply exact commands, fixtures, dependency
versions, and expected outcomes. Keep implementation readiness separate from
real-node acceptance until the local results are recorded.

Bindings generated from this repository preserve binary types. Text helpers
owned by a binding runtime/generator must be changed in that source, not in
generated files. Merging here dispatches updates to Rust, TypeScript, and Go
consumers; successful dispatch alone is not proof that their builds pass.
