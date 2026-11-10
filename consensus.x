// clang-format off
%#include "network_config.hh"
%#include "proposal.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

/// Names one kind of change consensus can make to the chain's rules.
///
/// Append-only, as `ConfigParamID` is: a type, once assigned, means that kind
/// of change forever.
enum ConsensusUpgradeType {
  kConsensusUpgradeConfigParam = 0
};

/// One change to the chain's rules, agreed by consensus alongside a block.
///
/// This is what an [`Upgrade`] holds. There is no `default` arm on purpose,
/// for the reason [`ConfigParam`] has none: a node that cannot name a change
/// cannot apply it, so an upgrade it does not recognize must fail to decode
/// rather than decode to something the node then ignores.
union ConsensusUpgrade switch (ConsensusUpgradeType type)
{
case kConsensusUpgradeConfigParam:
  /// Sets one network configuration parameter to the value stated. Every
  /// parameter the block's upgrades do not name keeps the value it has.
  ///
  /// `NetworkConfigV0::params` is a prefix of the id space, so an upgrade
  /// naming a parameter past the end of the list extends the list to reach
  /// it: each parameter in between is stated at the value already in force
  /// for it, which is the one its arm documents. The configuration that
  /// results is then the only one with those values in force, and has one
  /// hash.
  ConfigParam config_param;
};

/// A serialized [`ConsensusUpgrade`], carried opaquely in `ConsensusValue`.
///
/// Opaque so that a `ConsensusValue` decodes whatever its upgrades hold. A
/// node meeting an upgrade it cannot decode -- one a newer build defined --
/// can then still name the value, judge it invalid, and during nomination
/// vote for the same block without that upgrade. Were the list typed, the
/// whole value would fail to decode instead.
///
/// The bytes MUST be exactly one XDR-encoded `ConsensusUpgrade`, with nothing
/// after it. Anything else is malformed, and a value carrying it is invalid.
typedef opaque Upgrade<128>;

/// The upgrades one block carries.
///
/// The list MUST be in strictly ascending order of upgrade type and, among
/// `kConsensusUpgradeConfigParam` upgrades, of `ConfigParamID`. That permits
/// one upgrade per parameter and one arrangement per set of changes, so the
/// order in which a block's upgrades apply cannot matter and two proposers
/// selecting the same changes produce the same bytes. A value whose list
/// breaks the rule is invalid.
///
/// The changes are judged together, not one at a time: some parameters bound
/// each other (`kConfigParamMinRv32ArtifactVersion` and
/// `kConfigParamMaxRv32ArtifactVersion`, for one pair), and a block may need
/// to move both to get from one supportable configuration to another.
typedef Upgrade Upgrades<6>;

/// The block commitment externalized by consensus.
///
/// `ConsensusValue` is the small value that systems use to identify
/// a finalized Thruput block without the full transaction payload.
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

  /// Upgrades selected by consensus, taking effect after this block.
  ///
  /// The block itself executes under the configuration its
  /// `proposal_header.config_hash` commits to; the upgrades apply to that
  /// configuration once the block is committed, and the result is what the
  /// next block executes under and what its header commits to.
  ///
  /// Nothing in `proposal_header` depends on this list, so the same executed
  /// block can be paired with any subset of its upgrades. That is what lets a
  /// validator that has not agreed to an upgrade drop it during nomination
  /// and still vote for the block.
  ///
  /// A value is valid only if every upgrade is well formed, the list is in
  /// canonical order (see [`Upgrades`]), and the node can execute under the
  /// configuration that results. A node additionally nominates only upgrades
  /// its operator has armed, but must accept in balloting any valid upgrade a
  /// quorum is ratifying.
  Upgrades upgrades;
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
