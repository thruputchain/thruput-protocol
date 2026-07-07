// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// Captures pre-execution context (timestamp, block height), and
// post-execution results (transactions hash, stoarge hash, events hash).
struct ProposalHeader {
  ExtensionPoint ext;

  // The hash of the network name.
  NetworkHash network_hash;

  // The time of the block,
  // given to the executors by the coordinator before computation begins.
  TimePoint timestamp;

  // The height of this block.
  BlockHeight block_height;

  // The Merkle root hash of the transactions.
  TxsHash txs_hash;

  // The hash of the storage contents after this block is applied.
  StorageShortHash storage_hash;

  // The Merkle root hash of the events.
  EventsHash events_hash;
};

struct Proposal {
  ProposalHeader header;
  ProposalTxs transactions;
};

struct ProposalTxs {
  ParallelSignedTransactionHashBatch hash;
  ParallelNondeterministicProposalDataBatch nondeterministic_data;
};

typedef SHA256Hash ProposalHash; // #[rust(newtype)]

typedef Proposal *OptProposal;

// Used by SCP to seed pseudorandomness in leader election.
struct PrevProposalSummary {
  ConsensusValueHash value_hash;
};

} // namespace hogd
