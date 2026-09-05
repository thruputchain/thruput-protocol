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
  kConfigParamMaxNewContractsPerTx = 2,
  kConfigParamMaxBytestringLen = 3
};

/// One configuration parameter and the value in force for it.
///
/// Serves both uses of that pairing: `NetworkConfigV0` states a chain's
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

case kConfigParamMaxBytestringLen:
  /// Bytes one bytestring storage item may hold, checked where a contract
  /// writes one rather than where one is read, so that lowering it leaves
  /// existing items readable instead of stranding state.
  ///
  /// `kBytestringCeilingLen` bounds this. A chain must also keep it low
  /// enough that its own storage engine handles the largest item it thereby
  /// admits; the ceiling does not guarantee that.
  unsigned int max_bytestring_len;
};

/// The parameters a chain states, as a list rather than fixed fields. A new
/// parameter is then an id and a [`ConfigParam`] arm, with no new version here
/// and no change to the layout of anything embedding one.
///
/// `params` MUST be a prefix of the id space: ids run 0, 1, 2, ... in order,
/// with no gaps. The encoding is hashed into `ProposalHeader::config_hash`, so
/// permitting one arrangement per configuration is what gives it one hash. A
/// list that is unordered, repeats an id, or skips one must fail validation
/// rather than resolve to one of the values. The rule also bounds the list: a
/// prefix cannot be longer than the number of parameters that exist.
///
/// Ascending order alone would leave interior gaps legal, and a gap is what
/// makes the encoding ambiguous: a parameter at its default value could be
/// written down or left out. A prefix settles which -- below the list's length
/// a parameter is stated, past it it is not -- and makes resolving one an
/// index rather than a search.
///
/// A parameter absent from the list takes the value the protocol defines for
/// it. Absence says nothing about why: the list may be short because the
/// configuration predates the parameter, or because its creator declined to
/// state one it knew, and nothing on the wire tells those apart. A creator
/// SHOULD state every parameter it knows; a verifier cannot check that.
struct NetworkConfigV0 {
  ConfigParam params<>;
};

/// The consensus-critical execution parameters a block executes under.
///
/// The protocol blesses no value for any parameter: a chain states its
/// configuration at genesis, so there is nothing a node silently inherits.
///
/// One version, because `v0` states its parameters as a list: a new parameter
/// is an id and a [`ConfigParam`] arm, not a new arm here. The discriminant is
/// kept so that if a change ever does need one, it is a new case rather than a
/// silent reinterpretation of these bytes. A node meeting a version it cannot
/// name must fail to decode rather than guess what is in force.
union NetworkConfig switch (int v)
{
case 0:
  NetworkConfigV0 v0;
};

/// The network configuration committed to by ProposalHeader::config_hash.
/// New consensus-critical configuration belongs in this preimage.
struct ConfigHashPreimage {
  StorageCostModelXdr storage_cost_model;
  NetworkConfig network_config;
};

} // namespace hogd
