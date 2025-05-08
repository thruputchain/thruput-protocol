namespace hogd {

// A "batch" contains a set of proposed transactions.

typedef SHA256Hash BatchHash;

// BatchHeader is included in Proposals.
struct BatchHeader {
  BatchHash batch_hash;
  hyper batch_size;
};

struct BatchTransactions {
  ProposedTransaction transactions<>;
};

struct BatchMessage {
  BatchHeader batch_header;
  BatchTransactions batch_transactions;
};

} // namespace hogd
