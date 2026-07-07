// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

/// Inputs fixed before executing a candidate block.
///
/// Supplied by the coordinator when it asks the scheduler to build a proposal;
/// the parent block is identified by the surrounding RPC. Both fields are
/// copied into the resulting `ProposalHeader`.
struct ProposalContext {
  /// Block proposer. Nodes missing block data fetch it from the proposer.
  ValidatorID proposer;

  /// The block's timepoint, fixed by the coordinator before execution begins.
  TimePoint block_timepoint;
};

/// Header of a proposed block.
///
/// The consensus-facing summary of block execution: the fixed inputs of the
/// proposal together with the deterministic outputs of executing its
/// transactions. `ConsensusValue` embeds this header directly, so every field
/// is part of the block identity.
///
/// Travels on network.
struct ProposalHeader {
  ExtensionPoint ext;

  /// The hash of the network name, separating this network's blocks from
  /// those of other networks.
  NetworkHash network_hash;

  /// Block proposer. Nodes missing block data fetch it from the proposer.
  ValidatorID proposer;

  /// The block's timepoint, fixed by the coordinator before execution begins.
  TimePoint block_timepoint;

  /// The height of this block.
  BlockHeight block_height;

  /// The Merkle root hash of the transactions.
  TxsHash txs_hash;

  /// The hash of the storage contents after this block is applied.
  StorageShortHash storage_hash;

  /// The Merkle root hash of the events.
  EventsHash events_hash;
};

/// A candidate block: header plus the transaction metadata needed to
/// re-execute it.
///
/// Does not travel on network: nodes reconstruct it from a `ConsensusValue`
/// and its `ProposalTxs`.
struct Proposal {
  ProposalHeader header;
  ProposalTxs transactions;
};

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

typedef Proposal *OptProposal;

/// Summary of the previous finalized proposal, used by SCP leader selection.
///
/// Intentionally carries only the `ConsensusValueHash`: leader-election
/// pseudorandomness must not depend on transaction-payload availability.
struct PrevProposalSummary {
  ConsensusValueHash value_hash;
};

} // namespace hogd
