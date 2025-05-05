namespace hogd {

// A "batch" contains a set of proposed transactions.

typedef SHA256Hash BatchHash;

struct BatchHeader {
  BatchHash batch_hash;
  unsigned int batch_size;
};

struct BatchMessage {
  BatchHeader batch_header;
  ProposedTransaction transactions<>;
};

} // namespace hogd
