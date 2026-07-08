// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"
%#include "header.hh"

namespace hogd {
// clang-format on


/// Transaction-side payload for a proposal.
///
/// This is the payload a `ConsensusValue` commits to through
/// `ProposalTxsHash`. The signed transaction bodies travel separately, since
/// nodes usually already hold them from transaction dissemination.
///
/// Travels on network.
struct ProposalTxs {
  ExtensionPoint ext;

  /// Hashes of the block's signed transactions, in execution order.
  ParallelSignedTransactionHashBatch hash;

  /// Nondeterministic choices captured by the proposer, replayed by
  /// validators so re-execution reproduces the header outputs exactly.
  ParallelNondeterministicProposalDataBatch nondeterministic_data;
};

/// SHA-256 of the XDR-encoded `ProposalTxs`.
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
