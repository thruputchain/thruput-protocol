// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct Synopsis {
  // A unique identifier for this blockchain. If there are multiple instances of
  // the blockchain running, each one will have a different [network_id].
  unsigned hyper network_id;

  // The time of the block,
  // given to the executors by the coordinator before computation begins.
  TimePoint timestamp;

  // The height of this block.
  BlockHeight block_height;

  // The Merkle root hash of the transactions.
  TxsHash txs_hash;

  // The hash of the storage contents after this block is applied.
  StorageHash storage_hash;

  // The Merkle root hash of the events.
  EventsHash events_hash;
};

struct Proposal {
  Synopsis synopsis;
  ParallelSignedTransactionHashBatch transactions_hash;
  ParallelNondeterministicProposalDataBatch transactions_nondeterministic_data;
};

typedef SHA256Hash ProposalHash; // #[rust(newtype)]

typedef Proposal *OptProposal;

// Used by SCP to seed pseudorandomness in leader election.
struct PrevProposalSummary {
  ConsensusValueHash value_hash;
};

} // namespace hogd
