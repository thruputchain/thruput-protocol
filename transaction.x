// clang-format off
%#include "types.hh"
%#include "contract.hh"
%#include "retrocausal_queue.hh"
%#include "auth_claim.hh"

namespace hogd
{
// clang-format on

//==============================================================================
// Transactions and Invocations
//
// This module defines the transaction model for Thruput. Transactions are
// the fundamental unit of state modification in the system.
//
// Key concepts:
// - Each transaction invokes a contract method with specified parameters
// - Transactions include authorization claims and signatures
// - Transactions can deploy new contracts
// - Thruput executes transactions in parallel, using two-phase commit for conflict resolution
// - Proposers attach nondeterministic data to ensure deterministic re-execution
//
// Transaction lifecycle:
// 1. User constructs a Transaction with invocation details, auth claims, etc.
// 2. Signatures are added to create a SignedTransaction
// 3. Transaction is submitted to the network
// 4. A proposer executes the transaction and captures nondeterministic data
// 5. Proposer creates a ProposedTransaction and includes it in a block proposal
// 6. Validators re-execute using the nondeterministic data to verify correctness
//==============================================================================

//------------------------------------------------------------------------------
// Call Data and Return Values
//------------------------------------------------------------------------------

/// Opaque encoded call arguments passed to a contract invocation.
///
/// Contracts can encode calldata arbitrarily, but the SDK default uses
/// XDR serialization per RFC 4506 (<https://datatracker.ietf.org/doc/html/rfc4506>).
/// The SDK typically encodes a tuple or struct of the method's parameters.
///
/// Note: "TXS" refers to "traditional XDR serialization". A more compact
/// encoding is planned but not yet enabled.
typedef opaque Calldata<>;

/// Opaque encoded return value from a contract invocation.
///
/// Like Calldata, contracts can encode return values arbitrarily, but the
/// SDK default uses XDR serialization per RFC 4506 (<https://datatracker.ietf.org/doc/html/rfc4506>).
///
/// Unbounded here, as `Calldata` is: what a chain permits is stated by
/// `kConfigParamMaxReturnBufferLen` and enforced where the Return syscall
/// writes one, rather than where one is decoded. Nothing decodes a buffer
/// the local executor did not just build, so a bound here would constrain
/// what a configuration may state without guarding anything.
typedef opaque ReturnBuffer<>;

//------------------------------------------------------------------------------
// Invocations
//------------------------------------------------------------------------------

/// Specifies a contract method invocation with its parameters.
///
/// This struct is used both for the root transaction invocation and for
/// subinvocations made via the Invoke syscall.
struct Invocation {
  /// Address of the contract to invoke.
  ContractAddress invoked_address;

  /// 8-byte identifier of the contract method to call.
  ///
  /// See [`ContractEntrypointID`] in contract.x for how these are derived.
  ContractEntrypointID entrypoint;

  /// Maximum gas units available for this invocation.
  ///
  /// For the root transaction invocation, this is the total gas budget.
  /// For subinvocations via the Invoke syscall, this is capped at the
  /// remaining gas in the caller's frame. The SDK default is UINT64_MAX,
  /// meaning "use all remaining gas".
  GasAmount gas_limit;

  /// Encoded arguments to pass to the contract method.
  Calldata calldata;
};

enum InvocationFrameStatusCode {
  Return = 0,
  Fault = 1,
  Abort = 2
};

union InvocationFrameOutput switch (InvocationFrameStatusCode status_code)
{
case Return:
  ReturnBuffer return_buffer;
case Abort:
  ReturnBuffer abort_buffer;
case Fault:
  void;
};

//------------------------------------------------------------------------------
// Transaction Uniqueness and Replay Protection
//------------------------------------------------------------------------------

/// Ensures transaction uniqueness and prevents replay attacks.
///
/// Each transaction must include a uniquifier with two components:
/// 1. An expiry height - the transaction becomes invalid after this block
/// 2. A nonce - ensures uniqueness even if the same operation is repeated
///
/// The uniquifier is stored in the replay cache (see [`StorageKeyType::ReplayCache`]
/// in types.x) at the invoked contract's address to prevent replays.
///
/// Important: The replay cache considers the (nonce, block_expiry_height) pair as the
/// unique identifier. Two transactions with the same nonce but different expiry heights
/// do NOT conflict with each other. For example, (nonce=1, expiry=100) and (nonce=1, expiry=200)
/// can both be valid transactions.
struct Uniquifier {
  /// The block height after which this transaction becomes invalid.
  ///
  /// Transactions submitted after this height will be rejected. This prevents
  /// old transactions from being replayed indefinitely.
  ///
  /// Note: This is part of the uniqueness check - the pair (nonce, block_expiry_height)
  /// must be unique, not just the nonce alone.
  BlockHeight block_expiry_height;

  /// A 64-bit value chosen by the transaction creator.
  ///
  /// Combined with block_expiry_height and the invoked address, this ensures each
  /// transaction is globally unique. The nonce can be chosen arbitrarily (random,
  /// sequential, timestamp-based, etc.) as long as the (nonce, block_expiry_height)
  /// pair hasn't been used before for this address.
  unsigned hyper nonce;
};

//------------------------------------------------------------------------------
// Transactions
//------------------------------------------------------------------------------

/// A complete transaction that can be executed on the Thruput blockchain.
///
/// Transactions are the fundamental unit of state modification. Each transaction:
/// - Invokes a single contract method (which may make subinvocations)
/// - Includes claims about attached signatures, which must be verified before execution
///   can begin.  A transaction is invalid if any attached signatures are invalid
///   or if the attached signatures do not match the auth claims.
/// - Can deploy new contracts that will be available during execution
/// - Must have a [`Uniquifier`] that has never before been used for this address
struct Transaction {
  /// The root contract invocation for this transaction.
  Invocation invocation;

  /// Uniqueness and replay protection data.
  Uniquifier uniquifier;

  /// Contracts made available for deployment during this transaction.
  ///
  /// Attaching a contract does not deploy it: nothing reaches the chain
  /// unless a frame deploys it with the DeployContract syscall, which can then
  /// be invoked for the rest of the transaction. Contracts whose code is
  /// already on-chain do not need to be included here.
  Contract contracts_to_deploy<>;

  /// Authorization claim specifying required signatures.
  ///
  /// See [`AuthClaim`] in auth_claim.x for details.
  AuthClaim auth_claim;
};

//------------------------------------------------------------------------------
// Signatures and Signed Transactions
//------------------------------------------------------------------------------

/// A cryptographic signature paired with its key identifier.
///
/// The public_key_id indicates which key from an address's key set produced
/// this signature, allowing the signature to be matched against the transaction's
/// auth claims.
struct DecoratedSignature {
  /// The KeyID of the public key that created this signature.
  ///
  /// This is matched against the auth claims to determine if the signature
  /// satisfies the transaction's authorization requirements. Keys are
  /// registered and weighted in [`AddressAuthData`] (address_auth.x); see
  /// [`AuthClaim`] in auth_claim.x for how a claim selects them.
  unsigned int public_key_id; // uint32_t

  /// The cryptographic signature itself.
  ///
  /// See [`Signature`] in types.x for the union that supports different schemes.
  Signature signature;
};

/// Hash of a transaction body, the identifier users, events and indexers
/// know a transaction by.
///
/// This is the SHA-256 hash of the XDR-encoded [`Transaction`] -- the same
/// encoding the signatures cover (see [`SignedTransaction`]). It deliberately covers neither the
/// signatures wrapped around it by [`SignedTransaction`] nor the
/// nondeterministic data attached to it by [`ProposedTransaction`]:
///
///  - Excluding the signatures keeps the identifier fixed however the body
///    is signed, so a submitter can look up its transaction without knowing
///    which signing a block carried.
///  - Excluding the proposal data keeps the identifier computable by the
///    submitter at signing time. Nondeterministic proposal data does not
///    exist until a proposer has executed the transaction, so an identifier
///    covering it could not be used to look up one's own transaction.
///
/// Proposals do not name transactions by this hash: they commit to each
/// transaction's exact signed encoding by [`SignedTransactionHash`].
///
/// Uniqueness across blocks rests on replay protection -- the
/// [`Uniquifier`] every [`Transaction`] carries -- rather than on anything
/// in the preimage: two distinct commits can never share a hash, because
/// the same [`Transaction`] cannot commit twice.
typedef SHA256Hash TransactionHash;

/// Hash of one exact signed encoding of a transaction.
///
/// This is the SHA-256 hash of the canonical XDR of a [`SignedTransaction`]:
/// the [`Transaction`], its signatures and its `pubkey_claim_key`. Two
/// signings of one body share a [`TransactionHash`] but not a
/// [`SignedTransactionHash`].
///
/// Proposals name their transactions by this hash, so every validator
/// executes the encoding the proposer chose rather than whichever signing of
/// the body it happens to hold. A validator that holds a different signing
/// treats the transaction as missing and fetches the proposer's. It is not a
/// lookup key for users: re-signing a body changes it.
typedef SHA256Hash SignedTransactionHash;

/// A transaction with cryptographic signatures.
///
/// This is the form in which transactions are transmitted and stored.
/// Before execution, the signatures are verified against the auth claim.
///
/// Each signature is over
/// `cxs(DomainSeparator("Transaction")) || network_hash || xdr(tx)`: the
/// domain separator keeps it from being reinterpreted as a signature over
/// another object, and the network hash binds it to one network.
struct SignedTransaction {
  /// The transaction to execute.
  Transaction tx;

  /// Signatures that authorize this transaction.
  ///
  /// These signatures must satisfy the auth_claim in the transaction.
  /// See [`SignedTransaction`] for the message they sign.
  DecoratedSignature signatures<>;

  /// The public key a `kPubkeySignature` auth claim names by hash.
  ///
  /// Present exactly when the auth claim is `kPubkeySignature`, and then its
  /// [`PublicKeyHash`] must equal the claim's `pubkey_preimage.pubkey_hash`.
  /// It sits outside the signed [`Transaction`] because the claim already
  /// commits to it by hash; keeping it out of the claim keeps the claim that
  /// contracts read the same size for every scheme.
  PublicKey *pubkey_claim_key;
};

//------------------------------------------------------------------------------
// Batch Types
//------------------------------------------------------------------------------

/// A batch of transactions (without signatures).
typedef Transaction TransactionBatch<>;

/// A batch of signed transactions.
typedef SignedTransaction SignedTransactionBatch<>;

/// An optional signed transaction (pointer may be null).
typedef SignedTransaction *OptSignedTransaction;

/// A batch of optional signed transactions.
typedef OptSignedTransaction OptSignedTransactionBatch<>;

/// A batch of transaction hashes.
typedef TransactionHash TransactionHashBatch<>;

/// A batch of signed transaction hashes.
typedef SignedTransactionHash SignedTransactionHashBatch<>;

//------------------------------------------------------------------------------
// Proposed Transactions and Nondeterministic Data
//------------------------------------------------------------------------------

/// Nondeterministic data captured during transaction execution by the proposer.
///
/// Thruput executes transactions in parallel, which introduces nondeterminism
/// (e.g., from two-phase commit conflict resolution). To ensure validators can deterministically
/// re-execute transactions, the proposer captures all nondeterministic decisions
/// and includes them in the block proposal.
///
/// This allows validators to replay the exact same execution path as the proposer,
/// ensuring consensus on the transaction result.
struct NondeterministicProposalData {
  /// A bitstring of nondeterministic decisions made during execution.
  ///
  /// This includes:
  /// - Two-phase commit conflict resolution results from try_invoke frames (one boolean
  ///   per try_invoke frame that succeeds and attempts lock acquisition)
  /// - Other nondeterministic outcomes that must be consistent across validators
  ///
  /// Each bit represents a binary decision point encountered during execution.
  /// The bits are consumed sequentially as the transaction re-executes.
  opaque nondeterministic_bits<>;

  /// The length of nondeterministic_bits in bits (not bytes).
  ///
  /// Since nondeterministic_bits.size() returns the rounded-up length in bytes,
  /// this field tracks the exact bit count to avoid trailing garbage bits.
  unsigned int nondeterministic_bit_count;

  /// Retrocausal queue entries inserted by concurrent transactions in the same
  /// block that this transaction observed, so validators replay the same reads.
  ///
  /// An entry is recorded when a peek or consume reads a concurrent entry.
  /// Reads of entries from past blocks or inserted by this transaction itself
  /// record nothing. Entries appear in the order they were first observed
  /// during execution, interleaved across queues; within one queue they are
  /// that queue's concurrent entries in index order, starting at 0. Each
  /// (queue, index) is recorded once however many times it is read, so
  /// repeated peeks, or a peek followed by a consume, add a single entry.
  /// Whether each concurrent read found an entry is recorded separately, one
  /// bit per read, in nondeterministic_bits.
  QueueEntry observed_queue_entry_sequence<kMaxConcurrentRcqReadsPerTx>;
};

/// A signed transaction with nondeterministic execution data attached.
///
/// This is the form in which transactions are included in block proposals.
/// The proposer:
/// 1. Executes the signed transaction
/// 2. Captures all nondeterministic decisions (two-phase commit results, queue entries, etc.)
/// 3. Packages both into a ProposedTransaction
/// 4. Includes it in the proposed block
///
/// Validators then re-execute using the nondeterministic data to verify
/// the proposer's execution was correct.
struct ProposedTransaction {
  /// The signed transaction to execute.
  SignedTransaction signed_tx;

  /// Nondeterministic data captured during the proposer's execution.
  ///
  /// Validators use this to deterministically replay the same execution path.
  NondeterministicProposalData nondeterministic_proposal_data;
};

typedef ProposedTransaction ProposedTransactionBatch<>;

//------------------------------------------------------------------------------
// Transaction Statistics
//------------------------------------------------------------------------------

/// Transaction execution statistics available via the GetTransactionStatistics syscall.
///
/// These statistics provide runtime information about transaction execution,
/// primarily for debugging and monitoring. Some statistics may be disabled
/// in production builds.
enum TransactionStatistic {
  /// The amount of gas remaining in the current call frame.
  ///
  /// This can be queried to monitor gas consumption during execution.
  /// Note that this statistic may be disabled or return nondeterministic
  /// values in test configurations (see syscalls.yaml for details).
  GasRemaining = 0
};

} // namespace hogd
