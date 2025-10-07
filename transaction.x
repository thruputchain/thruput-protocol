
// clang-format off
%#include "types.hh"
%#include "contract.hh"
%#include "retrocausal_queue.hh"
%#include "auth_claim.hh"

namespace hogd
{
// clang-format on

// TXS encoding of the call arguments (as a tuple)
typedef opaque Calldata<>;

typedef opaque ReturnBuffer<>;

// A claim about sponsored gas units for a transaction.
struct GasClaim {
  // The contract being sponsored.
  ContractAddress sponsored_contract;
  // The number of gas units being sponsored.
  GasAmount amount;
};

struct Invocation {
  ContractAddress invoked_address;
  ContractEntrypointID entrypoint;
  GasAmount gas_limit;
  Calldata calldata;
};

enum InvokeFlag {
  kInvokeFlagNone = 0,
  kInvokeFlagTryInvoke = 0x00000001,
  kInvokeFlagReadOnly = 0x00000002,
  kInvokeFlagDelegateCall = 0x00000004,
};

typedef int InvokeFlagSet;

typedef opaque OriginID[16];

struct Uniquifier {
  BlockHeight block_expiry_height;
  unsigned hyper nonce;
};

struct Transaction {
  Invocation invocation;
  Uniquifier uniquifier;
  // New contracts to deploy.
  Contract contracts_to_deploy<>;
  AuthClaimData auth_claims;
  GasClaim gas_claims<>;
};

struct DecoratedSignature {
  unsigned int public_key_id; // uint32_t
  Signature signature;
};

typedef SHA256Hash SignedTransactionHash;

typedef DecoratedSignature DecoratedSignatureList<>;

struct SignedTransaction {
  Transaction tx;
  // These signatures get matched against the auth claims in the transaction.
  // These signatures are over corresponding AuthClaimPreimage objects.
  DecoratedSignatureList signatures<>;
};

// Nondeterministic data attached to a transaction by the proposer.
struct NondeterministicProposalData {
  // string of nondeterministic bits generated during the course
  // of the transaction.
  opaque nondeterministic_bits<>;
  // the length of the nondeterministic_bits string, in bits
  // (nondeterminstic_bits.size() returns the rounded-up length in bytes)
  unsigned int nondeterministic_bit_count;
  // sequence of queue entries observed by the proposer
  QueueEntry observed_queue_entry_sequence<>;
};

// A signed transaction, with the nondeterministic data from the proposer
// attached to it.
// TODO(petar): Who is the signer? The originator of the transaction or the
// validator proposing it?
// TODO(petar): Should the signature capture the non-deterministic data?
struct ProposedTransaction {
  SignedTransaction signed_tx;
  NondeterministicProposalData nondeterministic_proposal_data;
};

// Nominations, included in SCP messages, include only the ND data.
// The transactions themselves are disseminated through the overlay.
struct NominatedTransaction {
  NondeterministicProposalData nondeterministic_proposal_data;
};

enum TransactionStatistic {
  kTxStatGasRemaining = 0,
};

} // namespace hogd
