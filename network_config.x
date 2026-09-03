// clang-format off
%#include "storage_cost.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

/// Names one consensus-critical configuration parameter.
///
/// Append-only: an id, once assigned, means that parameter forever, and a
/// retired parameter keeps its id rather than freeing it for reuse.
enum ConfigParamID {
  kConfigParamMaxSHA256Buffers = 0,
  kConfigParamMaxCrossInvokeDepth = 1,
  kConfigParamMaxNewContractsPerTx = 2
};

/// One configuration parameter and the value in force for it.
///
/// Serves both uses of that pairing: `NetworkConfigV1` states a chain's
/// configuration as a list of these, and consensus carries one per parameter
/// being changed in `ConsensusValue::upgrades`, where everything a block does
/// not name keeps the value it already has. Each arm carries its own type, so
/// a future parameter need not be an `unsigned int`.
///
/// There is no `default` arm on purpose: a node that cannot name a parameter
/// cannot know what value is in force for it, so an unrecognized id must fail
/// to decode rather than decode to something the node then ignores.
union ConfigParam switch (ConfigParamID param)
{
case kConfigParamMaxSHA256Buffers:
  /// Concurrently open incremental SHA-256 buffers permitted per invocation
  /// frame (`SHA256Update`, `SHA256Copy`, `SHA256Finalize`).
  unsigned int max_sha256_buffers;

case kConfigParamMaxCrossInvokeDepth:
  /// Invocation frames one transaction may have open at once, counting every
  /// invoke rather than only the savepoint-pushing ones that
  /// `kMaxSavepointDepth` bounds. Each open frame holds a live contract
  /// runtime, so this is what stops a recursive call chain from growing until
  /// the executor runs out of room for it.
  unsigned int max_cross_invoke_depth;

case kConfigParamMaxNewContractsPerTx:
  /// Contracts one transaction may attach in `contracts_to_deploy`.
  ///
  /// Counted over what is attached rather than what a contract goes on to
  /// deploy: the executor holds every attached contract for the whole
  /// transaction, and the ones deployed are a subset chosen during execution.
  /// Attaching the same contract twice is rejected outright, so the count is
  /// over distinct contracts either way.
  ///
  /// Together with the per-contract blob size cap this is what bounds the
  /// transaction's final commit batch, which the executor sends to storage as
  /// a single message. A chain must set it low enough that the largest batch
  /// it admits still fits that message; hogd rejects a genesis that does not.
  unsigned int max_new_contracts_per_tx;
};

/// The parameters a chain created before they became a list states. Field
/// meanings are the ones documented on the matching [`ConfigParam`] arms.
struct NetworkConfigV0 {
  unsigned int max_sha256_buffers;
  unsigned int max_cross_invoke_depth;
};

/// The parameters a chain states, as a list rather than a fixed set of fields.
///
/// A new parameter is then an id and a [`ConfigParam`] arm, with no new
/// `NetworkConfig` version and no change to the layout of anything embedding
/// one -- which is what a flat struct could not offer.
///
/// `params` MUST be a prefix of the id space: ids run 0, 1, 2, ... in order,
/// with no gaps. The encoding is hashed into `ProposalHeader::config_hash`, so
/// two arrangements of one set of parameters would be two hashes for a
/// configuration the nodes agree on; permitting a single arrangement makes the
/// encoding canonical, and settles ordering, repetition and omission in one
/// rule. A list that is unordered, repeats an id, or skips one must fail
/// validation rather than resolve to one of the values. The rule also bounds
/// the list: a prefix cannot be longer than the number of parameters that
/// exist.
///
/// Ascending order alone would leave interior gaps legal, and a gap is what
/// makes the encoding ambiguous: a parameter sitting at its default value
/// could be written down or left out, so one configuration would have several
/// encodings and so several hashes. Requiring a prefix settles which -- below
/// the list's length a parameter is written down, past it a parameter is not
/// -- and makes resolving one an index rather than a search.
///
/// A parameter absent from the list takes the value the protocol defines for
/// it. Absence says nothing about why: a list may be short because the
/// configuration predates the parameter, or because its creator declined to
/// state one it knew about, and nothing on the wire tells those apart. Both
/// resolve the same way, so the difference is one of intent rather than of
/// behaviour. A creator SHOULD state every parameter it knows, so that a short
/// list means what it appears to; a verifier cannot check that, because the
/// encoding carries no record of what its creator knew.
///
/// Reading an absent parameter as its protocol-defined value is what lets a
/// chain predating that parameter keep running, and it is why adding one is
/// still a coordinated release: nodes have to agree on the value an omission
/// means, even though they no longer have to agree on a struct layout.
struct NetworkConfigV1 {
  ConfigParam params<>;
};

/// The consensus-critical execution parameters a block executes under.
///
/// The protocol blesses no value for any parameter: a chain states its
/// configuration at genesis, so there is nothing a node silently inherits.
///
/// Versioned as a union rather than extended in place. XDR is positional, so a
/// field appended to a struct changes the layout of everything embedding it,
/// and a chain created under the older layout could no longer be read. The
/// discriminant occupies the four bytes the leading `ExtensionPoint` used to,
/// so a configuration written before this union existed decodes as `v0` byte
/// for byte -- which is what that extension point was reserved for (see
/// `ExtensionPoint` in types.x).
///
/// `v1` states its parameters as a list, so a new parameter needs an id and a
/// [`ConfigParam`] arm rather than a new version here. A node that meets a
/// version it cannot name must fail to decode rather than guess which
/// parameters are in force.
union NetworkConfig switch (int v)
{
case 0:
  NetworkConfigV0 v0;
case 1:
  NetworkConfigV1 v1;
};

/// The network configuration committed to by ProposalHeader::config_hash.
/// New consensus-critical configuration belongs in this preimage.
struct ConfigHashPreimage {
  StorageCostModelXdr storage_cost_model;
  NetworkConfig network_config;
};

} // namespace hogd
