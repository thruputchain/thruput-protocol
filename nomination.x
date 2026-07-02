// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// The database's summary of the chain state after this block is applied,
// produced by the db when it proposes a block. hogd owns this struct and may
// evolve it without changes to the coordinator, which handles it as a unit
// and reads only its stable fields.
//
// Deliberately carries no timestamp (the block's one timestamp is assigned by
// consensus, in the BigValue) and no pointer to the previous block (chain
// linkage happens once, at the SmallValue level).
struct ChainState {
  // A unique identifier for this blockchain. If there are multiple instances
  // of the blockchain running, each one will have a different [network_id].
  unsigned hyper network_id;
  // The height of this block.
  BlockHeight block_height;
  // The Merkle root hash of the transactions.
  SHA256Hash txset_hash;
  // The hash of the database contents after this block is applied to the
  // database.
  DbHash db_hash;
  // The Merkle root hash of the events.
  SHA256Hash events_hash;
};

// XXX(petar): Nomination should be renamed to Proposal
struct Nomination {
  ChainState chain_state;
  ParallelSignedTransactionHashBatch transactions_hash;
  ParallelNondeterministicProposalDataBatch transactions_nondeterministic_data;
};

struct PrevNominationSummary {
  BlockHash block_hash;
};

} // namespace hogd
