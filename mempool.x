namespace hogd {

typedef SHA256Hash BatchID;

struct MempoolMessage {
  BatchID batch_id;
  unsigned int batch_size;
  Transaction transactions<>;
};

} // namespace hogd
