// clang-format off
%#include "auth_token.hh"
%#include "contract.hh"
%#include "hog_exec_constants.hh"
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
  kConfigParamMaxBytestringLen = 3,
  kConfigParamMaxContractSizeBytes = 4,
  kConfigParamMaxSavepointDepth = 5,
  kConfigParamMaxSHA256BufferBytes = 6,
  kConfigParamMaxAuthTokenDepth = 7,
  kConfigParamMaxRv32CodeBytes = 8,
  kConfigParamMaxRv32MemoryBytes = 9,
  kConfigParamMaxAuthTokens = 10,
  kConfigParamMaxCalldataLen = 11,
  kConfigParamMaxReturnBufferLen = 12,
  kConfigParamMaxTxGas = 13
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
  /// `kConfigParamMaxSavepointDepth` bounds. Each open frame holds a live contract
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
  /// Together with `kConfigParamMaxContractSizeBytes` this is what bounds the
  /// transaction's final commit batch, which the executor sends to storage as
  /// a single message. A chain must set the pair low enough that the largest
  /// batch it admits still fits that message; hogd rejects a genesis that
  /// does not.
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

case kConfigParamMaxContractSizeBytes:
  /// Bytes one attached contract's code blob (`ContractBlob.data`) may hold,
  /// checked before any attached contract is verified or executed. It is
  /// the same quantity `contract_deployment_cost_per_byte` charges for.
  ///
  /// `kDefaultMaxContractSizeBytes` is the value in force for a
  /// configuration that does not state one. The wire format does not bound
  /// `ContractBlob`, so nothing here caps what a chain may state: a chain
  /// must keep it low enough that its own storage engine stores the largest
  /// contract it thereby admits, that every attached contract still fits a
  /// transaction (`kMaxBytesSignedTransaction`), and that the commit batch
  /// `kConfigParamMaxNewContractsPerTx` bounds fits one storage message.
  /// hogd rejects a genesis that does not.
  unsigned int max_contract_size_bytes;

case kConfigParamMaxSavepointDepth:
  /// Storage savepoints one transaction may have open at once: one per
  /// `TryInvoke` frame still executing, plus the one the root commit takes.
  /// A `TryInvoke` past the limit fails as the guest would see any other
  /// refused call. `kMaxSavepointDepth` is the value in force for a
  /// configuration that does not state one.
  ///
  /// Every open savepoint is a live nested VM on one executor thread, so a
  /// chain must keep this within what its executors' stacks hold; hogd
  /// rejects a genesis above its build ceiling.
  unsigned int max_savepoint_depth;

case kConfigParamMaxSHA256BufferBytes:
  /// Legacy cumulative SHA-256 byte limit. Retained for wire compatibility
  /// and configuration hashing; no longer enforced. SHA256Update checks gas
  /// before processing input and keeps constant-size incremental state.
  unsigned int max_sha256_buffer_bytes;

case kConfigParamMaxAuthTokenDepth:
  /// Levels of `AuthTokenNode` nesting an auth token may carry, counted from
  /// its root, checked where a token is minted or forwarded into a view.
  /// `kAuthTokenMaxDepth` is the value in force for a configuration that
  /// does not state one. The wire type bounds a node's payload and its
  /// direct children (`kAuthTokenMaxLen`, `kAuthTokenMaxChildNodes`) but not
  /// the depth, so this is what bounds a token's total size.
  unsigned int max_auth_token_depth;

case kConfigParamMaxRv32CodeBytes:
  /// Bytes of code (`code_size` in the artifact header) an RV32 artifact may
  /// carry to be admitted as an attached contract.
  /// `kDefaultMaxRv32CodeBytes` is the value in force for a configuration
  /// that does not state one.
  ///
  /// Checked where a contract is attached, not where a deployed one is
  /// instantiated, so lowering it leaves deployed contracts runnable. The
  /// artifact format itself does not bound the field; hogd rejects a genesis
  /// above what its VM can translate.
  unsigned int max_rv32_code_bytes;

case kConfigParamMaxRv32MemoryBytes:
  /// Bytes of guest data memory (`memory_bytes` in the artifact header) an
  /// RV32 artifact may declare to be admitted as an attached contract.
  /// `kDefaultMaxRv32MemoryBytes` is the value in force for a configuration
  /// that does not state one.
  ///
  /// Checked at attachment like `kConfigParamMaxRv32CodeBytes`. Every
  /// invocation provisions and seeds the declared memory outside gas, so a
  /// chain raising this accepts that per-call cost; hogd rejects a genesis
  /// above what its VM provisions.
  unsigned int max_rv32_memory_bytes;

case kConfigParamMaxAuthTokens:
  /// Auth token ids one call may carry in a list: `Invoke`'s
  /// `owned_auth_token_ids_list` and `Return`'s `returned_auth_token_ids`,
  /// each read as a `[u32]` span.
  ///
  /// Checked against the span's length before the ids are read, so a list
  /// past the bound is refused without being copied and what a rejected call
  /// costs does not scale with the memory that held it. The ids in a list are
  /// distinct and owned by the frame naming them, so this bounds what one
  /// frame hands another in a single call rather than what a frame may hold.
  ///
  /// Neither wire type bounds its list, and no value was in force before this
  /// parameter: a list was limited only by the memory holding it. A
  /// configuration omitting this one is not continuing an older rule.
  unsigned int max_auth_tokens;

case kConfigParamMaxCalldataLen:
  /// Bytes of calldata one invocation may be given, whether a transaction
  /// supplies it in `Invocation::calldata` or a contract supplies it in
  /// `Invoke`'s `calldata` span.
  ///
  /// Checked before the bytes are copied, so an oversized call is refused
  /// rather than materialized. `Calldata` is `opaque<>`, so the wire type
  /// bounds neither form and this is what bounds them in execution.
  /// `kConfigParamMaxReturnBufferLen` bounds the other direction the same
  /// way.
  ///
  /// The executor holds a frame's calldata for the life of that frame and
  /// every open frame holds its own, so a chain must keep this within what
  /// `kConfigParamMaxCrossInvokeDepth` frames of it leave room for. No value
  /// was in force before this parameter.
  unsigned int max_calldata_len;

case kConfigParamMaxReturnBufferLen:
  /// Bytes one invocation frame may return, whether to a calling frame or,
  /// from the root frame, into `TxEventLog::root_output`.
  ///
  /// Checked where the Return syscall writes a buffer, which is the only
  /// place one is built. A root frame's buffer is committed to by the events
  /// root, so what a chain states here it stores and serves for every
  /// transaction; together with the event bounds it is what keeps a
  /// `TxEventLog` inside the RPC transport message limit.
  ///
  /// `ReturnBuffer` bounded itself at 1024 bytes before this parameter, so a
  /// configuration omitting this one is continuing an older rule rather than
  /// lifting it. The executor states the value it continues at.
  unsigned int max_return_buffer_len;

case kConfigParamMaxTxGas:
  /// Gas one transaction may budget: the most a root `Invocation::gas_limit`
  /// may state.
  ///
  /// Checked before any attached contract is verified or any body runs, so
  /// a transaction over the bound is refused outright rather than clamped:
  /// the budget a transaction signs is the one it executes under or none.
  /// Subinvocations are already capped at their caller's remaining gas, so
  /// bounding the root bounds every frame.
  ///
  /// Hog availability bounded a transaction's budget before this parameter,
  /// and nothing else did. A configuration omitting this one does not
  /// continue that rule: the value in force is `1,000,000,000`. A `GasAmount`
  /// rather than an `unsigned int` so that a chain may state any budget a
  /// transaction can.
  GasAmount max_tx_gas;
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

  /// The contract a root invocation of an undeployed address resolves to, as
  /// `GenesisConfiguration` states it and every `DbTip` carries it forward.
  ///
  /// It selects executing code, so a node running under a different one from
  /// its peers executes a different chain. Nothing else commits to it: a
  /// node's copy travels in the tip, which implementations are free to keep
  /// outside the state the storage hash covers, and hogd does. Committing to
  /// it here is what binds the value a node executes under to the one
  /// consensus agreed, rather than to whatever its own storage returns.
  DeployedContractHash default_wallet;
};

} // namespace hogd
