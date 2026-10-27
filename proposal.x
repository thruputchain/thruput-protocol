// clang-format off
%#include "validator.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"
%#include "header.hh"

namespace hogd {
// clang-format on

/// Transaction-side payload for a proposal.
///
/// This is the payload a `ConsensusValue` commits to through
/// `ProposalTxsHash`. The signed transactions travel separately, since nodes
/// usually already hold them from transaction dissemination. Because the
/// payload names each transaction by its [`SignedTransactionHash`], a node
/// that holds a different signing of a body treats that transaction as
/// missing and fetches the proposer's encoding.
///
/// Travels on network.
struct ProposalTxs {
  ExtensionPoint ext;

  /// Signed hashes of the block's transactions, in execution order: the
  /// exact encodings the block executes.
  ParallelSignedTransactionHashBatch signed_hash;

  /// Nondeterministic choices captured by the proposer, replayed by
  /// validators so re-execution reproduces the header outputs exactly.
  ParallelNondeterministicProposalDataBatch nondeterministic_data;
};

/// Compatibility commitment over `ProposalTxs`.
///
/// This is not SHA-256 of the complete canonical XDR. It XORs the hash of a
/// base value with empty batches, the hashes of each raw batch segment, and
/// the XDR hash of each batch index with its raw bytes removed.
typedef SHA256Hash ProposalTxsHash; // #[rust(newtype)]

/// A candidate block: header plus the transaction metadata needed to
/// re-execute it.
///
/// Does not travel on network: nodes reconstruct it from a `ConsensusValue`
/// and its `ProposalTxs`.
struct Proposal {
  ProposalHeader header;
  ProposalTxs transactions;
};

typedef Proposal *OptProposal;

/// Summary of the previous finalized proposal, used by SCP leader selection.
///
/// Intentionally carries only the `ConsensusValueHash`: leader-election
/// pseudorandomness must not depend on transaction-payload availability.
struct PrevProposalSummary {
  ConsensusValueHash value_hash;
};

} // namespace hogd
