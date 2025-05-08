namespace hogd {

// BlockHeight is the height of a block. It is signed to prevent overflows in
// calculations.
typedef hyper BlockHeight;

typedef SHA256Hash BlockHash;

// Proposal describes an individual block proposal.
// This message is used as an SCP application value.
struct Proposal {
  BlockHeight block_height;
  BlockHash block_hash;
  BlockHash prev_block_hash;
  BatchHash proposed_transaction_batches<>;
};

} // namespace hogd
