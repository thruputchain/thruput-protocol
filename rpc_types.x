// clang-format off

%#include "types.hh"
%#include "contract.hh"
%#include "transaction.hh"
%#include "address_auth.hh"
%#include "consensus.hh"
%#include "network_config.hh"

namespace hogd
{
// clang-format on

// An internal unique ID describing a block.
typedef unsigned hyper BlockID;

/// The contract-visible facts about the block an executor is running.
///
/// Passed to both executor open-block calls so that a block looks identical
/// to the executor whether it is being proposed or validated, and so that
/// everything a contract can observe about "the current block" comes from
/// one place rather than being inferred from the parent tip.
///
/// This is deliberately not `ProposalContext` (its `protocol` and `proposer`
/// are scheduler concerns, and `protocol` is not recoverable from a
/// `ProposalHeader` when validating) and not `ProposalHeader` (whose txs,
/// storage, events and config hashes are outputs of executing the block, so
/// they do not exist when it is opened).
///
/// Does not travel on network: the scheduler builds it per block, from the
/// coordinator's `ProposalContext` when proposing and from the proposal's
/// `ProposalHeader` when validating. A validator must take these values from
/// the proposal it is validating rather than regenerating them, or its
/// execution diverges from the proposer's and consensus splits.
struct BlockExecutionContext {
  /// Height of the block being executed -- the parent tip's height plus one.
  /// Supplied rather than derived so that height and timepoint have a single
  /// source; the executor is expected to check it against the tip it reads.
  BlockHeight block_height;

  /// The block's timepoint, fixed before execution begins. Unlike the
  /// height there is no way to recover this from the parent tip: the
  /// parent's timepoint is the previous block's.
  TimePoint block_timepoint;
};

struct DbTip {
  BlockID id;
  StorageLongHash storage_long_hash;
  ConsensusValue value;

  /// The chain-configured contract resolved for a root invocation of an
  /// address with no deployed contract (see
  /// SystemCallHandler::resolve_runtime). Set at genesis from
  /// GenesisConfiguration::default_wallet; carried forward verbatim by
  /// every subsequent commit, and committed to by this tip's own
  /// ProposalHeader::config_hash through ConfigHashPreimage.
  DeployedContractHash default_wallet;

  /// The execution parameters in force for the block that follows this tip.
  /// Set at genesis from GenesisConfiguration::network_config; carried forward
  /// verbatim by every commit that does not apply a [`ConfigUpgrade`].
  NetworkConfig network_config;
};

// Internal unique ID describing a transaction.
// Can be reused across blocks but cannot be reused within one block.
typedef unsigned hyper TransactionID;

// This is missing error codes, and is here purely as a placeholder.
// These are some of the error codes I suspect we will need, but these
// are not organized in any particular manner.
//
// TODO(geoff): This probably should get moved to a different file?
enum RPCError {
  kRPCNone = 0,
  // Lookup on an item in the database that does not exist.
  // Used by any database lookup RPC, not just for one type.
  kRPCNotFound = 1,
  // BlockID does not exist, or is not in correct state
  kRPCBadBlockID = 3,
  // bad storage modification
  kRPCStorageWriteFailed = 4,
  // tx validation or proposal failed
  kRPCTransactionFailed = 5,
  // Unimplemented RPC
  kRPCUnimplemented = 6,
  // Unrecoverable error in the server (i.e. OOM, DB corruption)
  kRPCUnrecoverable = 7
};

// The mode in which a block executes.
enum BlockExecutionMode {
  kBlockExecutionModeValidation = 0,
  kBlockExecutionModeProposal = 1,
  // Read-only access to the database.
  // Used for view RPCs, guaranteeing that the executor cannot accidentally
  // do a write operation when it should not be able to.
  kBlockExecutionModeViewing = 2
};

typedef int128_xdr StorageCost;

union ExpectedStorageCost switch (RPCError error)
{
case kRPCNone:
  StorageCost storage_cost;
default:
  void;
};

// Is this the XDR pattern we want?
union ExpectedContract switch (RPCError error)
{
case kRPCNone:
  Contract contract;
default:
  void;
};

union ExpectedDeployment switch (RPCError error)
{
case kRPCNone:
  DeployedContractHash deployed_hash;
default:
  void;
};

union ExpectedProposalData switch (RPCError error)
{
case kRPCNone:
  NondeterministicProposalData proposal_data;
default:
  void;
};

union ExpectedRetrocausalQueueBlock switch (RPCError error)
{
case kRPCNone:
  RetrocausalQueueBlock queue_block;
default:
  void;
};

union ExpectedQueueEntry switch (RPCError error)
{
case kRPCNone:
  QueueEntry queue_entry;
default:
  void;
};

union ExpectedDBTip switch (RPCError error)
{
case kRPCNone:
  DbTip db_tip;
default:
  void;
};

struct ViewingSnapshot {
  BlockID viewing_block_id;
  DbTip tip;
};

union ExpectedViewingSnapshot switch (RPCError error)
{
case kRPCNone:
  ViewingSnapshot snapshot;
default:
  void;
};

/// Typedef for a list of contract addresses.
typedef ContractAddress ContractAddressBatch<>;

} // namespace hogd
