namespace hogd {

typedef SHA256Hash BatchID;

struct MempoolMessage {
  BatchID batch_id;
  Transaction transactions<>;
};

} // namespace hogd
