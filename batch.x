namespace hogd {

// A "batch" contains a set of proposed transactions.

typedef SHA256Hash BatchHash;

struct BatchHeader {
  BlockHash target_block_hash;
  BlockHash target_prev_block_hash;
  BlockHeight target_block_height;
};

struct BatchTransactions {
  ProposedTransaction transactions<>;
};

struct BatchMessage {
  BatchHeader batch_header;
  BatchTransactions batch_transactions;
};

} // namespace hogd
