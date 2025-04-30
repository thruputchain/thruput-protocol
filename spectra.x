namespace hogd {

struct SpectraHeader {
  unsigned int num_payload_channels;
  unsigned int num_parity_channels;
  unsigned hyper payload_size;
  unsigned hyper shard_size;
  unsigned int shard_index;
};

} // namespace hogd
