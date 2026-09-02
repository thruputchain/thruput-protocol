// clang-format off
%#include "storage_cost.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

/// The parameters a chain created before `max_new_contracts_per_tx` existed
/// states. Field meanings are the ones documented on [`NetworkConfigV1`].
struct NetworkConfigV0 {
  unsigned int max_sha256_buffers;
  unsigned int max_cross_invoke_depth;
};

/// The parameters a chain states as of `max_new_contracts_per_tx`.
struct NetworkConfigV1 {
  /// Concurrently open incremental SHA-256 buffers permitted per invocation
  /// frame (`SHA256Update`, `SHA256Copy`, `SHA256Finalize`).
  unsigned int max_sha256_buffers;

  /// Invocation frames one transaction may have open at once, counting every
  /// invoke rather than only the savepoint-pushing ones that
  /// `kMaxSavepointDepth` bounds. Each open frame holds a live contract
  /// runtime, so this is what stops a recursive call chain from growing until
  /// the executor runs out of room for it.
  unsigned int max_cross_invoke_depth;

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

/// The consensus-critical execution parameters a block executes under.
///
/// Every parameter is a named field, so a configuration is structurally
/// complete: it cannot omit one, repeat one, or order them differently. The
/// protocol blesses no value for any of them either -- a chain states all of
/// them at genesis, so there is nothing a node can silently inherit and no way
/// for two node versions to disagree about what is in force.
///
/// Versioned as a union rather than extended in place. XDR is positional, so a
/// field appended to a struct changes the layout of everything embedding it,
/// and a chain created under the older layout could no longer be read. Each arm
/// instead states the parameters in force in full, and a chain keeps the arm it
/// was created with until an upgrade moves it.
///
/// The discriminant occupies the four bytes the leading `ExtensionPoint` used
/// to, so a configuration written before this union existed decodes as `v0`
/// byte for byte -- which is what that extension point was reserved for (see
/// `ExtensionPoint` in types.x).
///
/// Adding a parameter means adding an arm here that carries the previous arm's
/// fields plus the new one, along with a [`ConfigParamID`] and a
/// [`ConfigUpgrade`] arm. A node that meets an arm it cannot name must fail to
/// decode rather than guess which parameters are in force.
union NetworkConfig switch (int v)
{
case 0:
  NetworkConfigV0 v0;
case 1:
  NetworkConfigV1 v1;
};

/// Names one consensus-critical configuration parameter.
enum ConfigParamID {
  kConfigParamMaxSHA256Buffers = 0,
  kConfigParamMaxCrossInvokeDepth = 1,
  kConfigParamMaxNewContractsPerTx = 2
};

/// A change to one network configuration parameter.
///
/// Consensus carries these in `ConsensusValue::upgrades`, so a block that
/// changes several parameters carries one per parameter and everything it does
/// not name keeps the value it already has. The encoding is 8 bytes, well
/// inside the `Upgrade` that holds it.
///
/// There is no `default` arm on purpose: a node that cannot name a parameter
/// cannot apply a change to it, so an unrecognized id must fail to decode
/// rather than decode to something the node then ignores.
union ConfigUpgrade switch (ConfigParamID param)
{
case kConfigParamMaxSHA256Buffers:
  unsigned int max_sha256_buffers;
case kConfigParamMaxCrossInvokeDepth:
  unsigned int max_cross_invoke_depth;
case kConfigParamMaxNewContractsPerTx:
  unsigned int max_new_contracts_per_tx;
};

/// The network configuration committed to by ProposalHeader::config_hash.
/// New consensus-critical configuration belongs in this preimage.
struct ConfigHashPreimage {
  StorageCostModelXdr storage_cost_model;
  NetworkConfig network_config;
};

} // namespace hogd
