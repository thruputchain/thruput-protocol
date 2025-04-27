namespace hogd {

typedef SHA256Hash BatchID;

struct BatchHeader {
  BatchID batch_id;
  unsigned int batch_size;
};

struct MempoolMessage {
  BatchHeader batch_header;
  Transaction transactions<>;
};

} // namespace hogd
