#!/usr/bin/env python3
"""Independently re-derive and check test_vectors/pubkey_auth.json.

This shares no code with the Go generator in gen/. It decodes every XDR
blob in the file with its own XDR reader, re-encodes CXS with its own
encoder, derives the keys from their seeds and verifies signatures with
pyca/cryptography (OpenSSL), and runs its own model of the
kPubkeySignature checks over every negative vector.

Usage: python3 check_vectors.py [--mldsa-native ORACLE] [pubkey_auth.json]

With --mldsa-native, every ML-DSA-65 key, deterministic signature and
verification is also checked against mldsa-native (the library hogd
verifies with), through the oracle built from mldsa_native_oracle.c.

Needs `cryptography` >= 47 (ML-DSA support) built against an OpenSSL with
ML-DSA (3.5 or later).
"""

import hashlib
import json
import pathlib
import struct
import subprocess
import sys

from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives.asymmetric import ed25519, mldsa

ED25519, MLDSA65 = 0, 1
KEY_SIZE = {ED25519: 32, MLDSA65: 1952}
SIG_SIZE = {ED25519: 64, MLDSA65: 3309}
SCHEME_NAME = {ED25519: "Ed25519", MLDSA65: "MlDsa65"}
SOURCE_ADDRESS_AUTH_DATA, PUBKEY_SIGNATURE = 0, 1
AUTH_MALFORMED, SIGNATURE_VERIFICATION_FAILED = 1, 2


def sha256(*parts):
    h = hashlib.sha256()
    for p in parts:
        h.update(p)
    return h.digest()


# --- CXS (x23/x23/serialize_cxs.h) -----------------------------------------


def cxs_uint(v):
    if v <= 62:
        return bytes([v])
    for header, size in ((0x3F, 1), (0x7F, 2), (0xBF, 4), (0xFF, 8)):
        if v < 1 << (8 * size):
            return bytes([header]) + v.to_bytes(size, "little")
    raise ValueError(v)


def cxs_domain_separator(name):
    # ExtensionPoint discriminant 0, then opaque<256>.
    raw = name.encode("utf-8")
    return cxs_uint(0) + cxs_uint(len(raw)) + raw


def cxs_public_key(scheme, key):
    return cxs_uint(scheme) + key


def public_key_hash(scheme, key):
    return sha256(cxs_domain_separator("PublicKey"), cxs_public_key(scheme, key))


def preimage_cxs(pubkey_hash, nonce):
    return pubkey_hash + cxs_uint(nonce)


def account_address(pubkey_hash, nonce):
    return sha256(cxs_domain_separator("PubkeyAccount"), preimage_cxs(pubkey_hash, nonce))


# --- XDR reader --------------------------------------------------------------


class Reader:
    def __init__(self, data):
        self.data, self.pos = data, 0

    def take(self, n):
        if self.pos + n > len(self.data):
            raise ValueError("truncated")
        out = self.data[self.pos : self.pos + n]
        self.pos += n
        return out

    def u32(self):
        return struct.unpack(">I", self.take(4))[0]

    def i32(self):
        return struct.unpack(">i", self.take(4))[0]

    def u64(self):
        return struct.unpack(">Q", self.take(8))[0]

    def i64(self):
        return struct.unpack(">q", self.take(8))[0]

    def fixed(self, n):
        out = self.take(n)
        pad = self.take((-n) % 4)
        if any(pad):
            raise ValueError("nonzero XDR padding")
        return out

    def opaque(self):
        return self.fixed(self.u32())

    def done(self):
        if self.pos != len(self.data):
            raise ValueError("trailing bytes")


def read_transaction(r):
    tx = {
        "invoked_address": r.fixed(32),
        "entrypoint": r.fixed(8),
        "gas_limit": r.u64(),
        "calldata": r.opaque(),
        "block_expiry_height": r.i64(),
        "uniquifier_nonce": r.u64(),
    }
    if r.u32() != 0:
        raise ValueError("vectors never deploy contracts")
    claim_type = r.i32()
    if claim_type == PUBKEY_SIGNATURE:
        tx["claim"] = {"type": claim_type, "pubkey_hash": r.fixed(32), "nonce": r.u64()}
    elif claim_type == SOURCE_ADDRESS_AUTH_DATA:
        tx["claim"] = {"type": claim_type, "allowed_keys": r.u32(), "required_weight": r.u32()}
    else:
        raise ValueError("bad claim type")
    return tx


def read_scheme_union(r, sizes):
    scheme = r.i32()
    return scheme, r.fixed(sizes[scheme])


def read_signed_transaction(data):
    r = Reader(data)
    start = r.pos
    tx = read_transaction(r)
    tx_xdr = data[start : r.pos]
    sigs = []
    for _ in range(r.u32()):
        key_id = r.u32()
        sigs.append((key_id,) + read_scheme_union(r, SIG_SIZE))
    present = r.u32()
    if present not in (0, 1):
        raise ValueError("bad optional flag")
    key = read_scheme_union(r, KEY_SIZE) if present else None
    r.done()
    return tx, tx_xdr, sigs, key


def write_transaction(tx):
    """Re-encode a transaction from its decoded fields."""

    def fixed(b):
        return b + b"\0" * ((-len(b)) % 4)

    out = tx["invoked_address"] + tx["entrypoint"] + struct.pack(">Q", tx["gas_limit"])
    out += struct.pack(">I", len(tx["calldata"])) + fixed(tx["calldata"])
    out += struct.pack(">qQ", tx["block_expiry_height"], tx["uniquifier_nonce"])
    out += struct.pack(">I", 0)
    c = tx["claim"]
    out += struct.pack(">i", c["type"])
    if c["type"] == PUBKEY_SIGNATURE:
        out += c["pubkey_hash"] + struct.pack(">Q", c["nonce"])
    else:
        out += struct.pack(">II", c["allowed_keys"], c["required_weight"])
    return out


# --- Signatures --------------------------------------------------------------


class Oracle:
    """mldsa_native_oracle, driven over a pipe."""

    def __init__(self, path):
        self.proc = subprocess.Popen([path], stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True)
        self.calls = 0

    def ask(self, *args):
        self.proc.stdin.write(" ".join(a if isinstance(a, str) else a.hex() for a in args) + "\n")
        self.proc.stdin.flush()
        out = self.proc.stdout.readline().strip()
        if not out:
            raise RuntimeError("mldsa_native_oracle failed")
        self.calls += 1
        return out


ORACLE = None


def verify_signature(scheme, key, sig, msg):
    ok = verify_signature_pyca(scheme, key, sig, msg)
    if ORACLE and scheme == MLDSA65:
        eq("mldsa-native verify", ORACLE.ask("V", key, msg, sig) == "1", ok)
    return ok


def verify_signature_pyca(scheme, key, sig, msg):
    try:
        if scheme == ED25519:
            ed25519.Ed25519PublicKey.from_public_bytes(key).verify(sig, msg)
        else:
            mldsa.MLDSA65PublicKey.from_public_bytes(key).verify(sig, msg)
    except InvalidSignature:
        return False
    return True


def signing_preimage(network, tx_xdr):
    return cxs_domain_separator("Transaction") + network + tx_xdr


def check_auth(stx_xdr, network):
    """The kPubkeySignature checks, for an address with no AddressAuthData."""
    tx, tx_xdr, sigs, key = read_signed_transaction(stx_xdr)
    claim = tx["claim"]
    if claim["type"] != PUBKEY_SIGNATURE:
        return (AUTH_MALFORMED, "key on non-pubkey claim") if key else (None, "needs auth data")
    if key is None:
        return AUTH_MALFORMED, "missing key"
    if public_key_hash(*key) != claim["pubkey_hash"]:
        return AUTH_MALFORMED, "key hash mismatch"
    if len(sigs) != 1:
        return AUTH_MALFORMED, "signature count"
    key_id, sig_scheme, sig = sigs[0]
    if key_id != 0:
        return AUTH_MALFORMED, "key id"
    if sig_scheme != key[0]:
        return AUTH_MALFORMED, "scheme mismatch"
    if account_address(claim["pubkey_hash"], claim["nonce"]) != tx["invoked_address"]:
        return AUTH_MALFORMED, "address mismatch"
    if not verify_signature(key[0], key[1], sig, signing_preimage(network, tx_xdr)):
        return SIGNATURE_VERIFICATION_FAILED, "bad signature"
    return 0, "valid"


# --- Checks ------------------------------------------------------------------


def h(s):
    return bytes.fromhex(s)


def eq(what, got, want):
    def show(x):
        s = x.hex() if isinstance(x, bytes) else repr(x)
        return s if len(s) <= 200 else s[:200] + "..."

    if got != want:
        raise AssertionError(f"{what}: got {show(got)}, want {show(want)}")


def main():
    global ORACLE
    args = sys.argv[1:]
    if args[:1] == ["--mldsa-native"]:
        ORACLE = Oracle(args[1])
        args = args[2:]
    path = pathlib.Path(args[0] if args else pathlib.Path(__file__).with_name("pubkey_auth.json"))
    v = json.loads(path.read_text())
    n = 0

    for name, ds in v["domain_separators"].items():
        eq(f"domain separator {name}", h(ds["cxs"]), cxs_domain_separator(ds["name"]))
        n += 1
    eq("devnode network", h(v["networks"]["devnode"]), bytes(32))
    eq("execute entrypoint", h(v["constants"]["default_wallet_execute_entrypoint"]),
       sha256(b"DefaultWallet::0.1::execute")[:8])

    keys, k_seed = {}, {}
    for k in v["keys"]:
        seed, scheme = h(k["seed"]), k["scheme_value"]
        eq("scheme name", k["scheme"], SCHEME_NAME[scheme])
        if scheme == ED25519:
            sk = ed25519.Ed25519PrivateKey.from_private_bytes(seed)
            pk = sk.public_key().public_bytes_raw()
        else:
            sk = mldsa.MLDSA65PrivateKey.from_seed_bytes(seed)
            pk = sk.public_key().public_bytes_raw()
            if ORACLE:
                eq(f"{k['name']} mldsa-native public key", h(ORACLE.ask("K", seed)), pk)
        if k["name"] == "ed25519_devnode_bootstrap_0":
            eq("bootstrap seed", seed, sha256(b"groundhog-dev-accounts:account-0"))
        eq(f"{k['name']} public key", h(k["public_key"]), pk)
        eq(f"{k['name']} cxs", h(k["public_key_cxs"]), cxs_public_key(scheme, pk))
        eq(f"{k['name']} xdr", h(k["public_key_xdr"]),
           struct.pack(">i", scheme) + pk + b"\0" * ((-len(pk)) % 4))
        pkh = public_key_hash(scheme, pk)
        eq(f"{k['name']} hash", h(k["public_key_hash"]), pkh)
        eq(f"{k['name']} nonces", [a["nonce"] for a in k["accounts"]], ["0", "1", str(2**64 - 1)])
        for a in k["accounts"]:
            nonce = int(a["nonce"])
            eq("preimage", h(a["pubkey_account_preimage_cxs"]), preimage_cxs(pkh, nonce))
            eq("address", h(a["address"]), account_address(pkh, nonce))
            n += 1
        keys[k["name"]] = (scheme, sk, pk)
        k_seed[k["name"]] = k["seed"]

    signing = {}
    for s in v["signing"]:
        scheme, sk, pk = keys[s["key"]]
        network = h(s["network_hash"])
        eq("network", network, h(v["networks"][s["network"]]))
        stx = h(s["signed_transaction_xdr"])
        tx, tx_xdr, sigs, key = read_signed_transaction(stx)
        f = s["transaction"]
        want_tx = {
            "invoked_address": h(f["invoked_address"]), "entrypoint": h(f["entrypoint"]),
            "gas_limit": int(f["gas_limit"]), "calldata": h(f["calldata"]),
            "block_expiry_height": int(f["block_expiry_height"]),
            "uniquifier_nonce": int(f["uniquifier_nonce"]),
            "claim": {"type": PUBKEY_SIGNATURE, "pubkey_hash": h(f["pubkey_hash"]),
                      "nonce": int(f["account_nonce"])},
        }
        eq(f"{s['name']} decoded tx", tx, want_tx)
        eq(f"{s['name']} tx xdr", tx_xdr, h(s["transaction_xdr"]))
        eq(f"{s['name']} re-encoded tx", write_transaction(want_tx), tx_xdr)
        eq(f"{s['name']} pubkey hash", want_tx["claim"]["pubkey_hash"], public_key_hash(scheme, pk))
        eq(f"{s['name']} invoked address", want_tx["invoked_address"],
           account_address(public_key_hash(scheme, pk), 0))
        eq(f"{s['name']} key", key, (scheme, pk))
        eq(f"{s['name']} sigs", sigs, [(0, scheme, h(s["signature"]))])
        msg = signing_preimage(network, tx_xdr)
        eq(f"{s['name']} preimage", h(s["signing_preimage"]), msg)
        eq(f"{s['name']} tx hash", h(s["transaction_hash"]), sha256(tx_xdr))
        eq(f"{s['name']} stx sha256", h(s["signed_transaction_sha256"]), sha256(stx))
        if scheme == ED25519:
            # Ed25519 is deterministic: re-sign and compare bytes.
            eq(f"{s['name']} signature", h(s["signature"]), sk.sign(msg))
        elif ORACLE:
            eq(f"{s['name']} mldsa-native deterministic signature",
               h(s["signature"]), h(ORACLE.ask("S", h(k_seed[s["key"]]), msg)))
        eq(f"{s['name']} verdict", check_auth(stx, network), (0, "valid"))
        # The calldata is execute([one WalletCall]) in CXS.
        cd = h(f["calldata"])
        eq("calldata", cd, cxs_uint(1) + h(v["constants"]["native_token_address"]) + bytes(8)
           + cxs_uint(100_000) + cxs_uint(0))
        signing[s["name"]] = s
        n += 1

    for r in v["resigning"]:
        base = signing[r["of"]]
        stx = h(r["signed_transaction_xdr"])
        tx, tx_xdr, sigs, key = read_signed_transaction(stx)
        eq("resign tx", tx_xdr, h(base["transaction_xdr"]))
        eq("resign hash", h(r["transaction_hash"]), h(base["transaction_hash"]))
        eq("resign hash recomputed", sha256(tx_xdr), h(base["transaction_hash"]))
        if h(r["signature"]) == h(base["signature"]) or stx == h(base["signed_transaction_xdr"]):
            raise AssertionError("re-signing vector does not differ from its base")
        eq("resign verdict", check_auth(stx, h(base["network_hash"])), (0, "valid"))
        n += 1

    for neg in v["negative"]:
        stx = h(neg["signed_transaction_xdr"])
        tx, tx_xdr, _, _ = read_signed_transaction(stx)
        eq(f"{neg['name']} hash", h(neg["transaction_hash"]), sha256(tx_xdr))
        code, why = check_auth(stx, h(neg["network_hash"]))
        eq(f"{neg['name']} verdict ({why})", code, neg["expected"]["error_code"])
        n += 1

    extra = f", {ORACLE.calls} answered by mldsa-native" if ORACLE else ""
    print(f"{path}: {n} vectors checked{extra}")


if __name__ == "__main__":
    main()
