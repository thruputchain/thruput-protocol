// clang-format off
%#include "discovery.hh"
%#include "parallel.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// The db's proposal for a block, produced in propose. Deliberately carries no
// timestamp (the block's one timestamp is assigned by consensus, in the
// BigValue) and no pointer to the previous block (chain linkage happens once,
// at the SmallValue level).
//
// XXX(petar): Nomination should be renamed to Proposal

struct BackendHeader { // TODO pick better name
    // A unique identifier for this blockchain. If there are multiple instances
  // of the blockchain running, each one will have a different [network_id].
  unsigned hyper network_id;

  Timestamp timestamp;

  // The height of this block.
  BlockHeight block_height;
  // The Merkle root hash of the transactions.
  SHA256Hash txset_hash; // newtype this
  // sha256 of the database's 2 KiB DbHash after this block is applied. The
  // raw DbHash never travels in consensus structures; each node maintains it
  // locally and compares commitments.
  DbCommitment db_commitment; // ledger_snapshot_hash
  // The Merkle root hash of the events.
  SHA256Hash events_hash; // newtype this
};

struct Nomination { // -> rename to Proposal

  BackendHeader foo;

  ParallelSignedTransactionHashBatch transactions_hash;
  ParallelNondeterministicProposalDataBatch transactions_nondeterministic_data;
};

struct PrevNominationSummary {
  BlockHash block_hash;
};

} // namespace hogd
