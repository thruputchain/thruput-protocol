// Command gen writes test_vectors/pubkey_auth.json: cross-language vectors
// for standalone-pubkey accounts (kPubkeySignature) with Ed25519 and
// ML-DSA-65 keys.
//
// Everything is built from first principles here, with no generated XDR
// bindings: XDR and CXS are written by hand below, Ed25519 and ML-DSA-65 come
// from the Go standard library (crypto/ed25519, crypto/mldsa). The rules
// follow hogd:
//
//   - CXS: x23/x23/serialize_cxs.h
//   - DomainSeparator and the pubkey account address:
//     hogd/crypto/domain_separators.h
//   - The transaction signing preimage: hogd/auth_claim/signature_preimage.h
//   - The transaction hash: sha256(xdr(Transaction)), as hogd's
//     sha256(const T&) in hogd/crypto/crypto.h
//   - The devnode bootstrap keys: hogd/devnode/bootstrap_accounts.cc
//   - The pubkey claim checks: hogd/auth_claim/verify.cc, extended with the
//     pubkey_claim_key rules of transaction.x
//
// Run from this directory:
//
//	go run . -o ../pubkey_auth.json
//
// The output is deterministic. check_vectors.py in the parent directory
// re-derives and re-checks it independently.
package main

import (
	"crypto/ed25519"
	"crypto/mldsa"
	"crypto/sha256"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"log"
	"os"
	"strconv"
	"strings"
)

// Protocol constants (types.x, auth_claim.x, address_auth.x).
const (
	schemeEd25519 int32 = 0
	schemeMlDsa65 int32 = 1

	claimSourceAddressAuthData int32 = 0
	claimPubkeySignature       int32 = 1

	kDefaultNewAddressKeyID uint32 = 0

	errAuthMalformed               = 1
	errSignatureVerificationFailed = 2

	ed25519PublicKeySize = 32
	ed25519SignatureSize = 64
	mlDsa65PublicKeySize = 1952
	mlDsa65SignatureSize = 3309
)

// ---------------------------------------------------------------------------
// XDR (RFC 4506): big-endian, every item padded to a multiple of 4 bytes.

type xdrWriter struct{ b []byte }

func (w *xdrWriter) u32(v uint32) { w.b = binary.BigEndian.AppendUint32(w.b, v) }
func (w *xdrWriter) i32(v int32)  { w.u32(uint32(v)) }
func (w *xdrWriter) u64(v uint64) { w.b = binary.BigEndian.AppendUint64(w.b, v) }
func (w *xdrWriter) i64(v int64)  { w.u64(uint64(v)) }

// fixed writes opaque[N]: the bytes, then zero padding to a 4-byte boundary.
func (w *xdrWriter) fixed(b []byte) {
	w.b = append(w.b, b...)
	for len(w.b)%4 != 0 {
		w.b = append(w.b, 0)
	}
}

// opaque writes opaque<>: a uint32 length, then the bytes as for fixed.
func (w *xdrWriter) opaque(b []byte) {
	w.u32(uint32(len(b)))
	w.fixed(b)
}

// ---------------------------------------------------------------------------
// CXS (x23/x23/serialize_cxs.h). Unsigned integers take the shortest of:
//
//	v <= 62           one byte, v itself
//	v <= 0xff         0x3f, then 1 byte little-endian
//	v <= 0xffff       0x7f, then 2 bytes little-endian
//	v <= 0xffffffff   0xbf, then 4 bytes little-endian
//	otherwise         0xff, then 8 bytes little-endian
//
// Enums and union discriminants encode as their integer value (all the ones
// used here are small and non-negative, so signed and unsigned agree).
// opaque[N] is the raw bytes with no length and no padding; opaque<> is a
// CXS uint32 length followed by the bytes. Structs are their fields in
// order; unions are the discriminant then the arm.

func cxsUint(b []byte, v uint64) []byte {
	switch {
	case v <= 62:
		return append(b, byte(v))
	case v <= 0xff:
		return append(b, 0x3f, byte(v))
	case v <= 0xffff:
		return binary.LittleEndian.AppendUint16(append(b, 0x7f), uint16(v))
	case v <= 0xffffffff:
		return binary.LittleEndian.AppendUint32(append(b, 0xbf), uint32(v))
	default:
		return binary.LittleEndian.AppendUint64(append(b, 0xff), v)
	}
}

func cxsOpaqueVar(b, data []byte) []byte {
	return append(cxsUint(b, uint64(len(data))), data...)
}

// ---------------------------------------------------------------------------
// Protocol types.

// cxsDomainSeparator encodes DomainSeparator{ext = ExtensionPoint(0),
// domain_separator = name} (preimage.x): the ExtensionPoint's int
// discriminant 0 (no arm), then opaque<256> name.
func cxsDomainSeparator(name string) []byte {
	b := cxsUint(nil, 0)
	return cxsOpaqueVar(b, []byte(name))
}

var (
	dsPublicKey     = cxsDomainSeparator("PublicKey")
	dsPubkeyAccount = cxsDomainSeparator("PubkeyAccount")
	dsTransaction   = cxsDomainSeparator("Transaction")
)

type PublicKey struct {
	Scheme int32
	Key    []byte
}

func (k PublicKey) cxs() []byte { return append(cxsUint(nil, uint64(k.Scheme)), k.Key...) }

func (k PublicKey) xdr(w *xdrWriter) {
	w.i32(k.Scheme)
	w.fixed(k.Key)
}

// Hash is the PublicKeyHash (types.x).
func (k PublicKey) Hash() [32]byte {
	return sha256.Sum256(cat(dsPublicKey, k.cxs()))
}

type Signature struct {
	Scheme int32
	Sig    []byte
}

func (s Signature) xdr(w *xdrWriter) {
	w.i32(s.Scheme)
	w.fixed(s.Sig)
}

// preimageCxs encodes PubkeyAccountPreimage{pubkey_hash, nonce}.
func preimageCxs(pubkeyHash [32]byte, nonce uint64) []byte {
	return cxsUint(append([]byte(nil), pubkeyHash[:]...), nonce)
}

func pubkeyAccountAddress(pubkeyHash [32]byte, nonce uint64) [32]byte {
	return sha256.Sum256(cat(dsPubkeyAccount, preimageCxs(pubkeyHash, nonce)))
}

type AuthClaim struct {
	Type int32
	// kPubkeySignature
	PubkeyHash [32]byte
	Nonce      uint64
	// kSourceAddressAuthData
	AllowedKeys    uint32
	RequiredWeight uint32
}

func (c AuthClaim) xdr(w *xdrWriter) {
	w.i32(c.Type)
	switch c.Type {
	case claimPubkeySignature:
		w.fixed(c.PubkeyHash[:])
		w.u64(c.Nonce)
	case claimSourceAddressAuthData:
		w.u32(c.AllowedKeys)
		w.u32(c.RequiredWeight)
	default:
		panic("unknown claim type")
	}
}

// Transaction (transaction.x), with contracts_to_deploy always empty.
type Transaction struct {
	InvokedAddress    [32]byte
	Entrypoint        [8]byte
	GasLimit          uint64
	Calldata          []byte
	BlockExpiryHeight int64
	UniquifierNonce   uint64
	AuthClaim         AuthClaim
}

func (t Transaction) xdrTo(w *xdrWriter) {
	// Invocation
	w.fixed(t.InvokedAddress[:])
	w.fixed(t.Entrypoint[:])
	w.u64(t.GasLimit)
	w.opaque(t.Calldata)
	// Uniquifier
	w.i64(t.BlockExpiryHeight)
	w.u64(t.UniquifierNonce)
	// contracts_to_deploy<>
	w.u32(0)
	t.AuthClaim.xdr(w)
}

func (t Transaction) XDR() []byte {
	var w xdrWriter
	t.xdrTo(&w)
	return w.b
}

// Hash is the TransactionHash: sha256(xdr(Transaction)).
func (t Transaction) Hash() [32]byte { return sha256.Sum256(t.XDR()) }

// SigningPreimage is cxs(DomainSeparator("Transaction")) || network_hash ||
// xdr(tx), the exact bytes a signature covers.
func (t Transaction) SigningPreimage(network [32]byte) []byte {
	return cat(dsTransaction, network[:], t.XDR())
}

type DecoratedSignature struct {
	KeyID     uint32
	Signature Signature
}

type SignedTransaction struct {
	Tx             Transaction
	Signatures     []DecoratedSignature
	PubkeyClaimKey *PublicKey
}

func (s SignedTransaction) XDR() []byte {
	var w xdrWriter
	s.Tx.xdrTo(&w)
	w.u32(uint32(len(s.Signatures)))
	for _, d := range s.Signatures {
		w.u32(d.KeyID)
		d.Signature.xdr(&w)
	}
	if s.PubkeyClaimKey == nil {
		w.u32(0)
	} else {
		w.u32(1)
		s.PubkeyClaimKey.xdr(&w)
	}
	return w.b
}

// ---------------------------------------------------------------------------
// Default wallet calldata. The invocation is the default wallet's
// `execute(calls: Vec<WalletCall>)` (thruput-integration-test-contracts
// default_wallet), whose calldata is CXS.

// defaultWalletExecute is sdk_entrypoint_derivation("DefaultWallet", "0.1.0",
// "execute"): the first 8 bytes of sha256("DefaultWallet::0.1::execute").
// hogd's default_wallet_parity_test pins its method id, 0xc3edb11fdd6d5d58.
var defaultWalletExecute = func() [8]byte {
	h := sha256.Sum256([]byte("DefaultWallet::0.1::execute"))
	var e [8]byte
	copy(e[:], h[:8])
	return e
}()

type WalletCall struct {
	Target     [32]byte
	Entrypoint [8]byte
	GasLimit   uint64
	Calldata   []byte
}

func executeCalldata(calls []WalletCall) []byte {
	b := cxsUint(nil, uint64(len(calls)))
	for _, c := range calls {
		b = append(b, c.Target[:]...)
		b = append(b, c.Entrypoint[:]...)
		b = cxsUint(b, c.GasLimit)
		b = cxsOpaqueVar(b, c.Calldata)
	}
	return b
}

// nativeTokenAddress is genesis_contract_address(kAddressNativeToken): the
// big-endian GenesisContractAddresses value in the last four bytes.
var nativeTokenAddress = func() [32]byte {
	var a [32]byte
	a[31] = 1
	return a
}()

// The one call each vector's wallet makes. It is a placeholder: auth is
// checked before execution, so these vectors do not depend on what the call
// does. Its all-zero entrypoint names no native token method.
var placeholderCall = WalletCall{
	Target:   nativeTokenAddress,
	GasLimit: 100_000,
	Calldata: []byte{},
}

// ---------------------------------------------------------------------------
// Keys.

type signer interface {
	PublicKey() PublicKey
	Sign(msg []byte) Signature
}

type ed25519Signer struct{ sk ed25519.PrivateKey }

func (s ed25519Signer) PublicKey() PublicKey {
	return PublicKey{schemeEd25519, []byte(s.sk.Public().(ed25519.PublicKey))}
}

func (s ed25519Signer) Sign(msg []byte) Signature {
	return Signature{schemeEd25519, ed25519.Sign(s.sk, msg)}
}

type mlDsa65Signer struct{ sk *mldsa.PrivateKey }

func (s mlDsa65Signer) PublicKey() PublicKey {
	return PublicKey{schemeMlDsa65, s.sk.PublicKey().Bytes()}
}

// Sign is deterministic ML-DSA (FIPS 204 Algorithm 2 with rnd = 0^32), pure,
// with an empty context string.
func (s mlDsa65Signer) Sign(msg []byte) Signature {
	return s.signCtx(msg, "")
}

func (s mlDsa65Signer) signCtx(msg []byte, ctx string) Signature {
	sig, err := s.sk.SignDeterministic(msg, &mldsa.Options{Context: ctx})
	check(err)
	return Signature{schemeMlDsa65, sig}
}

type keyDef struct {
	name       string
	scheme     int32
	seed       []byte
	derivation string
	signer     signer
}

func makeKeys() []keyDef {
	var keys []keyDef

	// hogd/devnode/bootstrap_accounts.cc: the Ed25519 seed of bootstrap
	// account i is sha256(seed + ":" + "account-" + i), with the default seed
	// "groundhog-dev-accounts".
	bootSeed := sha256.Sum256([]byte("groundhog-dev-accounts:account-0"))
	// RFC 8032 section 7.1, TEST 1.
	rfcSeed := mustHex("9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60")
	for _, k := range []struct {
		name, derivation string
		seed             []byte
	}{
		{"ed25519_devnode_bootstrap_0",
			`sha256("groundhog-dev-accounts:account-0"): devnode bootstrap account 0 (hogd/devnode/bootstrap_accounts.cc, default seed "groundhog-dev-accounts")`,
			bootSeed[:]},
		{"ed25519_rfc8032_test1", "RFC 8032 section 7.1 TEST 1 secret key", rfcSeed},
	} {
		keys = append(keys, keyDef{k.name, schemeEd25519, k.seed, k.derivation,
			ed25519Signer{ed25519.NewKeyFromSeed(k.seed)}})
	}

	// FIPS 204 key generation seeds ξ.
	xi0 := make([]byte, 32)
	xi1 := make([]byte, 32)
	for i := range 32 {
		xi0[i] = byte(i)
		xi1[i] = byte(0xff - i)
	}
	for _, k := range []struct {
		name, derivation string
		seed             []byte
	}{
		{"mldsa65_seed_00..1f", "ξ = 0x00 0x01 ... 0x1f", xi0},
		{"mldsa65_seed_ff..e0", "ξ = 0xff 0xfe ... 0xe0", xi1},
	} {
		sk, err := mldsa.NewPrivateKey(mldsa.MLDSA65(), k.seed)
		check(err)
		keys = append(keys, keyDef{k.name, schemeMlDsa65, k.seed, k.derivation, mlDsa65Signer{sk}})
	}
	return keys
}

// ---------------------------------------------------------------------------
// Reference verifier for a SignedTransaction whose invoked address has no
// AddressAuthData registered. It is the kPubkeySignature check of
// hogd/auth_claim/verify.cc, plus the pubkey_claim_key rules of
// transaction.x. It returns 0 for success or an AuthVerifyErrorCode, and the
// reason.

func verify(s SignedTransaction, network [32]byte) (int, string) {
	claim := s.Tx.AuthClaim
	if claim.Type != claimPubkeySignature {
		if s.PubkeyClaimKey != nil {
			return errAuthMalformed, "pubkey_claim_key is set but the auth claim is not kPubkeySignature"
		}
		return -1, "not a pubkey claim; needs AddressAuthData, out of scope"
	}
	if s.PubkeyClaimKey == nil {
		return errAuthMalformed, "kPubkeySignature claim without pubkey_claim_key"
	}
	key := *s.PubkeyClaimKey
	if key.Hash() != claim.PubkeyHash {
		return errAuthMalformed, "PublicKeyHash of pubkey_claim_key differs from the claim's pubkey_hash"
	}
	if len(s.Signatures) != 1 {
		return errAuthMalformed, "kPubkeySignature claim requires exactly one signature"
	}
	sig := s.Signatures[0]
	if sig.KeyID != kDefaultNewAddressKeyID {
		return errAuthMalformed, "pubkey claim signature must use key id kDefaultNewAddressKeyID (0)"
	}
	if sig.Signature.Scheme != key.Scheme {
		return errAuthMalformed, "signature scheme differs from the pubkey_claim_key scheme"
	}
	if pubkeyAccountAddress(claim.PubkeyHash, claim.Nonce) != s.Tx.InvokedAddress {
		return errAuthMalformed, "address derived from the claim's PubkeyAccountPreimage differs from the invoked address"
	}
	msg := s.Tx.SigningPreimage(network)
	switch key.Scheme {
	case schemeEd25519:
		if !ed25519.Verify(key.Key, msg, sig.Signature.Sig) {
			return errSignatureVerificationFailed, "Ed25519 signature does not verify"
		}
	case schemeMlDsa65:
		pk, err := mldsa.NewPublicKey(mldsa.MLDSA65(), key.Key)
		if err != nil {
			return errSignatureVerificationFailed, "ML-DSA-65 public key does not decode"
		}
		if err := mldsa.Verify(pk, msg, sig.Signature.Sig, nil); err != nil {
			return errSignatureVerificationFailed, "ML-DSA-65 signature does not verify"
		}
	default:
		return errAuthMalformed, "unknown scheme"
	}
	return 0, "valid"
}

// ---------------------------------------------------------------------------
// JSON output.

type hexBytes []byte

func (h hexBytes) MarshalJSON() ([]byte, error) { return json.Marshal(hex.EncodeToString(h)) }

type u64String uint64

func (u u64String) MarshalJSON() ([]byte, error) {
	return json.Marshal(strconv.FormatUint(uint64(u), 10))
}

type DomainSeparatorOut struct {
	Name string   `json:"name"`
	Cxs  hexBytes `json:"cxs"`
}

type AccountOut struct {
	Nonce               u64String `json:"nonce"`
	PubkeyAccountPreimg hexBytes  `json:"pubkey_account_preimage_cxs"`
	Address             hexBytes  `json:"address"`
}

type KeyOut struct {
	Name           string       `json:"name"`
	Scheme         string       `json:"scheme"`
	SchemeValue    int32        `json:"scheme_value"`
	Seed           hexBytes     `json:"seed"`
	SeedDerivation string       `json:"seed_derivation"`
	PublicKey      hexBytes     `json:"public_key"`
	PublicKeyCxs   hexBytes     `json:"public_key_cxs"`
	PublicKeyXdr   hexBytes     `json:"public_key_xdr"`
	PublicKeyHash  hexBytes     `json:"public_key_hash"`
	Accounts       []AccountOut `json:"accounts"`
}

type TxFieldsOut struct {
	InvokedAddress    hexBytes   `json:"invoked_address"`
	Entrypoint        hexBytes   `json:"entrypoint"`
	GasLimit          u64String  `json:"gas_limit"`
	Calldata          hexBytes   `json:"calldata"`
	BlockExpiryHeight string     `json:"block_expiry_height"`
	UniquifierNonce   u64String  `json:"uniquifier_nonce"`
	AuthClaimType     string     `json:"auth_claim_type"`
	PubkeyHash        hexBytes   `json:"pubkey_hash,omitempty"`
	AccountNonce      *u64String `json:"account_nonce,omitempty"`
}

type SigningOut struct {
	Name                    string      `json:"name"`
	Key                     string      `json:"key"`
	Network                 string      `json:"network"`
	NetworkHash             hexBytes    `json:"network_hash"`
	Transaction             TxFieldsOut `json:"transaction"`
	TransactionXdr          hexBytes    `json:"transaction_xdr"`
	SigningPreimage         hexBytes    `json:"signing_preimage"`
	TransactionHash         hexBytes    `json:"transaction_hash"`
	Signature               hexBytes    `json:"signature"`
	SignatureKind           string      `json:"signature_kind"`
	SignedTransactionXdr    hexBytes    `json:"signed_transaction_xdr"`
	SignedTransactionSha256 hexBytes    `json:"signed_transaction_sha256"`
}

type ResignOut struct {
	Name                 string   `json:"name"`
	Description          string   `json:"description"`
	Of                   string   `json:"of"`
	Signature            hexBytes `json:"signature"`
	SignatureKind        string   `json:"signature_kind"`
	SignedTransactionXdr hexBytes `json:"signed_transaction_xdr"`
	TransactionHash      hexBytes `json:"transaction_hash"`
}

type ExpectedOut struct {
	Result    string `json:"result"`
	ErrorCode int    `json:"error_code"`
	Reason    string `json:"reason"`
}

type NegativeOut struct {
	Name                 string      `json:"name"`
	Description          string      `json:"description"`
	Base                 string      `json:"base"`
	Network              string      `json:"network"`
	NetworkHash          hexBytes    `json:"network_hash"`
	SignedTransactionXdr hexBytes    `json:"signed_transaction_xdr"`
	TransactionHash      hexBytes    `json:"transaction_hash"`
	Expected             ExpectedOut `json:"expected"`
}

type Output struct {
	Comment          string                        `json:"_comment"`
	FormatVersion    int                           `json:"format_version"`
	DomainSeparators map[string]DomainSeparatorOut `json:"domain_separators"`
	Networks         map[string]hexBytes           `json:"networks"`
	Constants        map[string]any                `json:"constants"`
	Keys             []KeyOut                      `json:"keys"`
	Signing          []SigningOut                  `json:"signing"`
	Resigning        []ResignOut                   `json:"resigning"`
	Negative         []NegativeOut                 `json:"negative"`
}

var schemeNames = map[int32]string{schemeEd25519: "Ed25519", schemeMlDsa65: "MlDsa65"}

var errorNames = map[int]string{
	errAuthMalformed:               "kAuthMalformed",
	errSignatureVerificationFailed: "kSignatureVerificationFailed",
}

func main() {
	out := flag.String("o", "../pubkey_auth.json", "output file")
	hedgedPath := flag.String("hedged", "testdata/hedged_signature.hex",
		"file holding the pinned hedged ML-DSA signature for the re-signing vector; written if missing")
	flag.Parse()

	networks := map[string][32]byte{
		// hogd/devnode: kDefaultRuntimeNetworkHash and
		// kDefaultHostedDevnetNetworkHash are both all zero.
		"devnode": {},
		"test":    sha256.Sum256([]byte("thruput-protocol test vectors network")),
		"other":   sha256.Sum256([]byte("thruput-protocol test vectors other network")),
	}

	o := Output{
		Comment:       "Generated by test_vectors/gen (go run . -o ../pubkey_auth.json). Do not edit by hand; see test_vectors/README.md.",
		FormatVersion: 1,
		DomainSeparators: map[string]DomainSeparatorOut{
			"PublicKey":     {"PublicKey", dsPublicKey},
			"PubkeyAccount": {"PubkeyAccount", dsPubkeyAccount},
			"Transaction":   {"Transaction", dsTransaction},
		},
		Networks: map[string]hexBytes{},
		Constants: map[string]any{
			"kDefaultNewAddressKeyID":           kDefaultNewAddressKeyID,
			"default_wallet_execute_entrypoint": hexBytes(defaultWalletExecute[:]),
			"native_token_address":              hexBytes(nativeTokenAddress[:]),
		},
	}
	for n, h := range networks {
		o.Networks[n] = hexBytes(h[:])
	}

	keys := makeKeys()
	byName := map[string]keyDef{}
	nonces := []uint64{0, 1, ^uint64(0)}
	for _, k := range keys {
		byName[k.name] = k
		pk := k.signer.PublicKey()
		var w xdrWriter
		pk.xdr(&w)
		h := pk.Hash()
		ko := KeyOut{
			Name: k.name, Scheme: schemeNames[k.scheme], SchemeValue: k.scheme,
			Seed: k.seed, SeedDerivation: k.derivation,
			PublicKey: pk.Key, PublicKeyCxs: pk.cxs(), PublicKeyXdr: w.b, PublicKeyHash: h[:],
		}
		for _, n := range nonces {
			a := pubkeyAccountAddress(h, n)
			ko.Accounts = append(ko.Accounts, AccountOut{u64String(n), preimageCxs(h, n), a[:]})
		}
		o.Keys = append(o.Keys, ko)
	}

	// A default-wallet `execute` from the key's nonce-0 account.
	makeTx := func(k keyDef, uniquifierNonce uint64) Transaction {
		h := k.signer.PublicKey().Hash()
		return Transaction{
			InvokedAddress:    pubkeyAccountAddress(h, 0),
			Entrypoint:        defaultWalletExecute,
			GasLimit:          10_000_000,
			Calldata:          executeCalldata([]WalletCall{placeholderCall}),
			BlockExpiryHeight: 1000,
			UniquifierNonce:   uniquifierNonce,
			AuthClaim:         AuthClaim{Type: claimPubkeySignature, PubkeyHash: h, Nonce: 0},
		}
	}
	sign := func(k keyDef, tx Transaction, network [32]byte) SignedTransaction {
		pk := k.signer.PublicKey()
		return SignedTransaction{
			Tx:             tx,
			Signatures:     []DecoratedSignature{{kDefaultNewAddressKeyID, k.signer.Sign(tx.SigningPreimage(network))}},
			PubkeyClaimKey: &pk,
		}
	}
	mustValid := func(name string, s SignedTransaction, network [32]byte) {
		if code, reason := verify(s, network); code != 0 {
			log.Fatalf("%s: expected valid, got %d (%s)", name, code, reason)
		}
	}

	// Positive vectors: each key's first entry on the devnode network, the
	// second on the test network, so both an all-zero and a non-zero network
	// hash are covered.
	type base struct {
		key     keyDef
		network string
		stx     SignedTransaction
	}
	bases := map[string]base{}
	for i, k := range keys {
		netName := "devnode"
		if i%2 == 1 {
			netName = "test"
		}
		net := networks[netName]
		tx := makeTx(k, uint64(i+1))
		s := sign(k, tx, net)
		mustValid(k.name, s, net)
		name := "sign_" + k.name
		bases[name] = base{k, netName, s}
		txh := tx.Hash()
		an := u64String(0)
		stxXdr := s.XDR()
		stxHash := sha256.Sum256(stxXdr)
		kind := "Ed25519 (RFC 8032, deterministic)"
		if k.scheme == schemeMlDsa65 {
			kind = "ML-DSA-65 deterministic (FIPS 204 Algorithm 2, rnd = 0^32), pure, empty context"
		}
		o.Signing = append(o.Signing, SigningOut{
			Name: name, Key: k.name, Network: netName, NetworkHash: net[:],
			Transaction: TxFieldsOut{
				InvokedAddress: tx.InvokedAddress[:], Entrypoint: tx.Entrypoint[:],
				GasLimit: u64String(tx.GasLimit), Calldata: tx.Calldata,
				BlockExpiryHeight: strconv.FormatInt(tx.BlockExpiryHeight, 10),
				UniquifierNonce:   u64String(tx.UniquifierNonce),
				AuthClaimType:     "kPubkeySignature",
				PubkeyHash:        tx.AuthClaim.PubkeyHash[:], AccountNonce: &an,
			},
			TransactionXdr: tx.XDR(), SigningPreimage: tx.SigningPreimage(net),
			TransactionHash: txh[:], Signature: s.Signatures[0].Signature.Sig,
			SignatureKind: kind, SignedTransactionXdr: stxXdr, SignedTransactionSha256: stxHash[:],
		})
	}

	// Re-signing: a second valid ML-DSA signature over the same transaction.
	// ML-DSA signing is hedged by default, so one key has many valid
	// signatures for one message. Go's crypto/mldsa does not take a chosen
	// rnd, so the hedged signature is made once and pinned in testdata.
	{
		b := bases["sign_mldsa65_seed_00..1f"]
		net := networks[b.network]
		msg := b.stx.Tx.SigningPreimage(net)
		ml := b.key.signer.(mlDsa65Signer)
		var hedged []byte
		if data, err := os.ReadFile(*hedgedPath); err == nil {
			hedged = mustHex(strings.TrimSpace(string(data)))
		} else if errors.Is(err, os.ErrNotExist) {
			hedged, err = ml.sk.Sign(nil, msg, &mldsa.Options{})
			check(err)
			check(os.WriteFile(*hedgedPath, []byte(hex.EncodeToString(hedged)+"\n"), 0o644))
		} else {
			check(err)
		}
		s2 := b.stx
		s2.Signatures = []DecoratedSignature{{kDefaultNewAddressKeyID, Signature{schemeMlDsa65, hedged}}}
		mustValid("resign", s2, net)
		if string(hedged) == string(b.stx.Signatures[0].Signature.Sig) {
			log.Fatal("pinned hedged signature equals the deterministic one")
		}
		h := s2.Tx.Hash()
		o.Resigning = append(o.Resigning, ResignOut{
			Name: "resign_mldsa65_seed_00..1f_hedged",
			Description: "The transaction of sign_mldsa65_seed_00..1f with a second, hedged (random rnd) ML-DSA-65 signature. " +
				"Both SignedTransactions are valid and differ, but the transaction hash, which covers only the unsigned Transaction, is the same.",
			Of: "sign_mldsa65_seed_00..1f", Signature: hedged, SignatureKind: "ML-DSA-65 hedged (random rnd, pinned), pure, empty context",
			SignedTransactionXdr: s2.XDR(), TransactionHash: h[:],
		})
	}

	// Negative vectors. Each breaks exactly one rule of a valid base.
	addNeg := func(name, desc, baseName string, s SignedTransaction, netName string, want int) {
		net := networks[netName]
		code, reason := verify(s, net)
		if code != want {
			log.Fatalf("%s: expected %d, got %d (%s)", name, want, code, reason)
		}
		h := s.Tx.Hash()
		o.Negative = append(o.Negative, NegativeOut{
			Name: name, Description: desc, Base: baseName, Network: netName, NetworkHash: net[:],
			SignedTransactionXdr: s.XDR(), TransactionHash: h[:],
			Expected: ExpectedOut{Result: "reject", ErrorCode: code, Reason: errorNames[code] + ": " + reason},
		})
	}
	resign := func(k keyDef, tx Transaction, net [32]byte) []DecoratedSignature {
		return []DecoratedSignature{{kDefaultNewAddressKeyID, k.signer.Sign(tx.SigningPreimage(net))}}
	}

	for _, pair := range [][2]string{
		{"ed25519_devnode_bootstrap_0", "ed25519_rfc8032_test1"},
		{"mldsa65_seed_00..1f", "mldsa65_seed_ff..e0"},
	} {
		k, other := byName[pair[0]], byName[pair[1]]
		bn := "sign_" + k.name
		b := bases[bn]
		net := networks[b.network]
		short := schemeNames[k.scheme]

		// pubkey_claim_key is another key of the same scheme.
		s := b.stx
		ok := other.signer.PublicKey()
		s.PubkeyClaimKey = &ok
		addNeg("key_hash_mismatch_"+short,
			"pubkey_claim_key is a different "+short+" key from the one the claim's pubkey_hash names; the signature is still the named key's.",
			bn, s, b.network, errAuthMalformed)

		// No pubkey_claim_key.
		s = b.stx
		s.PubkeyClaimKey = nil
		addNeg("missing_key_"+short, "kPubkeySignature claim with pubkey_claim_key absent.", bn, s, b.network, errAuthMalformed)

		// Claim nonce changed after signing: the claim no longer derives the
		// invoked address.
		s = b.stx
		s.Tx.AuthClaim.Nonce = 1
		addNeg("altered_claim_nonce_"+short,
			"The claim's account nonce changed from 0 to 1 after signing, invoked address unchanged: the claim derives a different address than the one invoked.",
			bn, s, b.network, errAuthMalformed)

		// Claim nonce and invoked address both changed consistently: the
		// structure is valid but the signature covers the old transaction.
		s = b.stx
		s.Tx.AuthClaim.Nonce = 1
		s.Tx.InvokedAddress = pubkeyAccountAddress(s.Tx.AuthClaim.PubkeyHash, 1)
		addNeg("altered_claim_nonce_and_address_"+short,
			"The claim's account nonce and the invoked address both changed to the nonce-1 account after signing, consistently: the claim is well formed but the signature is over the original transaction.",
			bn, s, b.network, errSignatureVerificationFailed)

		// Signed for another network.
		otherNet := "other"
		s = b.stx
		s.Signatures = resign(k, s.Tx, networks[otherNet])
		addNeg("wrong_network_"+short,
			"Signed over the network hash of 'other', submitted to '"+b.network+"'.",
			bn, s, b.network, errSignatureVerificationFailed)

		// Two signatures.
		s = b.stx
		s.Signatures = append(append([]DecoratedSignature{}, b.stx.Signatures...), b.stx.Signatures...)
		addNeg("two_signatures_"+short, "The valid signature twice: a kPubkeySignature claim takes exactly one.", bn, s, b.network, errAuthMalformed)

		// Wrong key id.
		s = b.stx
		s.Signatures = []DecoratedSignature{{1, b.stx.Signatures[0].Signature}}
		addNeg("wrong_key_id_"+short, "The valid signature with public_key_id 1 instead of kDefaultNewAddressKeyID (0).", bn, s, b.network, errAuthMalformed)

		// One flipped bit in the signature.
		s = b.stx
		bad := append([]byte(nil), b.stx.Signatures[0].Signature.Sig...)
		bad[len(bad)/2] ^= 0x01
		s.Signatures = []DecoratedSignature{{kDefaultNewAddressKeyID, Signature{k.scheme, bad}}}
		addNeg("malformed_signature_bitflip_"+short, "The valid signature with one bit flipped in its middle byte.", bn, s, b.network, errSignatureVerificationFailed)

		// A non-pubkey claim carrying a pubkey_claim_key.
		s = b.stx
		s.Tx.AuthClaim = AuthClaim{Type: claimSourceAddressAuthData, AllowedKeys: 1, RequiredWeight: 1}
		s.Signatures = resign(k, s.Tx, net)
		addNeg("extra_key_source_claim_"+short,
			"kSourceAddressAuthData claim (allowed_keys = 1, required_weight = 1), correctly signed, with pubkey_claim_key set: the key may only be present for kPubkeySignature claims. Rejected before any AddressAuthData lookup.",
			bn, s, b.network, errAuthMalformed)
	}

	// Scheme mismatches. An Ed25519 and an ML-DSA-65 key cannot share bytes
	// (their lengths differ), so a mismatch is a signature of one scheme
	// presented for a key of the other.
	{
		ed, ml := byName["ed25519_devnode_bootstrap_0"], byName["mldsa65_seed_00..1f"]
		bEd, bMl := bases["sign_"+ed.name], bases["sign_"+ml.name]

		s := bMl.stx
		s.Signatures = resign(ed, s.Tx, networks[bMl.network])
		addNeg("scheme_mismatch_ed25519_signature_for_mldsa65_key",
			"ML-DSA-65 claim and pubkey_claim_key, with a valid Ed25519 signature (by ed25519_devnode_bootstrap_0) over the same preimage.",
			"sign_"+ml.name, s, bMl.network, errAuthMalformed)

		s = bEd.stx
		s.Signatures = resign(ml, s.Tx, networks[bEd.network])
		addNeg("scheme_mismatch_mldsa65_signature_for_ed25519_key",
			"Ed25519 claim and pubkey_claim_key, with a valid ML-DSA-65 signature (by mldsa65_seed_00..1f) over the same preimage.",
			"sign_"+ed.name, s, bEd.network, errAuthMalformed)

		// The claim names the Ed25519 key; the attached key, which signs, is
		// the ML-DSA one.
		s = bEd.stx
		mpk := ml.signer.PublicKey()
		s.PubkeyClaimKey = &mpk
		s.Signatures = resign(ml, s.Tx, networks[bEd.network])
		addNeg("scheme_mismatch_mldsa65_key_for_ed25519_claim",
			"The claim names ed25519_devnode_bootstrap_0 by hash; pubkey_claim_key is mldsa65_seed_00..1f, which signs. The hash comparison rejects it before any signature check.",
			"sign_"+ed.name, s, bEd.network, errAuthMalformed)
	}

	// ML-DSA-specific malformed signatures.
	{
		ml := byName["mldsa65_seed_00..1f"]
		bn := "sign_" + ml.name
		b := bases[bn]
		net := networks[b.network]

		s := b.stx
		ones := make([]byte, mlDsa65SignatureSize)
		for i := range ones {
			ones[i] = 0xff
		}
		s.Signatures = []DecoratedSignature{{kDefaultNewAddressKeyID, Signature{schemeMlDsa65, ones}}}
		addNeg("malformed_signature_all_ff_MlDsa65", "A 3309-byte ML-DSA-65 signature of all 0xff bytes (not a well-formed encoding).", bn, s, b.network, errSignatureVerificationFailed)

		s = b.stx
		sig := append([]byte(nil), b.stx.Signatures[0].Signature.Sig...)
		// The last byte of the hint encoding counts the hints of the final
		// polynomial; an out-of-range count is malformed (FIPS 204 HintBitUnpack).
		sig[len(sig)-1] = 0xff
		s.Signatures = []DecoratedSignature{{kDefaultNewAddressKeyID, Signature{schemeMlDsa65, sig}}}
		addNeg("malformed_signature_hint_count_MlDsa65", "The valid signature with its last byte (the final hint count) set to 0xff, beyond ω = 55.", bn, s, b.network, errSignatureVerificationFailed)

		s = b.stx
		s.Signatures = []DecoratedSignature{{kDefaultNewAddressKeyID, ml.signer.(mlDsa65Signer).signCtx(s.Tx.SigningPreimage(net), "thruput")}}
		addNeg("nonempty_context_MlDsa65", `A deterministic ML-DSA-65 signature over the right preimage but with context string "thruput": transaction signatures use the empty context.`, bn, s, b.network, errSignatureVerificationFailed)
	}

	data, err := json.MarshalIndent(o, "", "  ")
	check(err)
	check(os.WriteFile(*out, append(data, '\n'), 0o644))
	fmt.Fprintf(os.Stderr, "wrote %s: %d keys, %d signing, %d re-signing, %d negative vectors\n",
		*out, len(o.Keys), len(o.Signing), len(o.Resigning), len(o.Negative))
}

func cat(parts ...[]byte) []byte {
	var b []byte
	for _, p := range parts {
		b = append(b, p...)
	}
	return b
}

func mustHex(s string) []byte {
	b, err := hex.DecodeString(s)
	check(err)
	return b
}

func check(err error) {
	if err != nil {
		log.Fatal(err)
	}
}
