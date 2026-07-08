// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"
%#include "validator.hh"

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

} // namespace hogd
