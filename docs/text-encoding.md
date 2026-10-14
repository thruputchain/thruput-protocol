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

Use base58 for Thruput RPC, CLI JSON, dApp/wallet messages, persisted Thruput byte
strings, and default human output. This includes network hashes, transaction and
block hashes, signatures, code, calldata, return data, storage bytes, and topics.
Numbers retain their existing JSON number/decimal-string rules. External
identifiers (Git SHAs, checksums required by external formats) retain their own
formats. Pagination cursors remain opaque bytes: changing their outer encoding
does not authorize clients to inspect or rebuild their contents.

Payload limits are specified by each field/API, in decoded bytes. They must not
be silently reduced as part of this migration. Test encoder/decoder performance
at realistic transaction/code sizes before enabling base58 for large payloads;
ordinary repeated-division implementations have quadratic conversion cost.

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
| Any hash, signature, or opaque bytes | Base58 | Base58 |
| Ed25519 seed, explicitly exported | Base58 | Explicit S export supported |

Only human-facing typed parsers accept StrKey in addition to base58. Machine
fields remain base58. A G key is not a wallet address; C/G conversion must not
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

Bindings generated from this repository preserve binary types. Text helpers
owned by a binding runtime/generator must be changed in that source, not in
generated files. Merging here dispatches updates to Rust, TypeScript, and Go
consumers; successful dispatch alone is not proof that their builds pass.
