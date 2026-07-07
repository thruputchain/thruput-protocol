// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct ProposalContext {
  // Block proposer. Also used to repair missing block data.
  ValidatorID proposer;

  // The time of the block,
  // given to the executors by the coordinator before computation begins.
  TimePoint block_timepoint;
};

// Captures pre-execution context (timestamp, block height), and
// post-execution results (transactions hash, stoarge hash, events hash).
// Travels on network.
struct ProposalHeader {
  ExtensionPoint ext;

  // The hash of the network name.
  NetworkHash network_hash;

  // Block proposer. Also used to repair missing block data.
  ValidatorID proposer;

  // The time of the block,
  // given to the executors by the coordinator before computation begins.
  TimePoint block_timepoint;

  // The height of this block.
  BlockHeight block_height;

  // The Merkle root hash of the transactions.
  TxsHash txs_hash;

  // The hash of the storage contents after this block is applied.
  StorageShortHash storage_hash;

  // The Merkle root hash of the events.
  EventsHash events_hash;
};

// Only inside validator.
struct Proposal {
  ProposalHeader header;
  ProposalTxs transactions;
};

// Travels on network.
struct ProposalTxs {
  ExtensionPoint ext;
  ParallelSignedTransactionHashBatch hash;
  ParallelNondeterministicProposalDataBatch nondeterministic_data;
};

typedef SHA256Hash ProposalTxsHash; // #[rust(newtype)]

typedef Proposal *OptProposal;

// Used by SCP to seed pseudorandomness in leader election.
struct PrevProposalSummary {
  ConsensusValueHash value_hash;
};

} // namespace hogd
