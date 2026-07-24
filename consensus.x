// clang-format off
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

/// A serialized protocol upgrade, carried opaquely in `ConsensusValue`.
typedef opaque Upgrade<128>;

/// The block commitment externalized by consensus.
///
/// `ConsensusValue` is the small value that systems use to identify
/// a finalized Groundhog block without the full transaction payload.
/// Its XDR hash is the block identity (`ConsensusValueHash`), so every
/// field is consensus-critical.
///
/// Travels on network.
struct ConsensusValue {
  // Network protocol version.
  Protocol protocol;

  ExtensionPoint ext;

  /// Hash of the parent block's `ConsensusValue`, linking the chain.
  ConsensusValueHash prev_hash;

  /// The executed header of the proposed block.
  ProposalHeader proposal_header;

  /// Commits to the block's transaction payload, which is kept out of the
  /// value for compactness and travels separately in `ConsensusBasis`.
  ProposalTxsHash proposal_txs_hash;

  /// Protocol upgrades selected by consensus to take effect at this block.
  Upgrade upgrades<6>;
};

/// The validation payload for a consensus value.
///
/// `ConsensusBasis` pairs a `ConsensusValue` with the transaction payload it
/// commits to but does not contain, letting a node reconstruct the `Proposal`
/// as `{ header: value.proposal_header, transactions: proposal_txs }` and
/// validate it. Gossiped and used during catchup.
///
/// Consensus agrees only on `value`; the basis has no consensus identity of its own.
///
/// Travels on network.
struct ConsensusBasis {
  ExtensionPoint ext;
  ConsensusValue value;
  ProposalTxs proposal_txs;
};

} // namespace hogd
