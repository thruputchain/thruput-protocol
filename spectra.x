namespace hogd {

struct SpectraHeader {
  unsigned int num_data_channels;
  unsigned int num_parity_channels;
  unsigned hyper payload_size;
  unsigned hyper shard_size;
};

} // namespace hogd
