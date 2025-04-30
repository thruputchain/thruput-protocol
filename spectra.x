namespace hogd {

typedef hyper SpectraTransmissionID;

struct SpectraHeader {
  SpectraTransmissionID transmission_id;
  unsigned int num_payload_channels;
  unsigned int num_parity_channels;
  unsigned hyper payload_size;
  unsigned hyper shard_size;
  unsigned int shard_index;
};

} // namespace hogd
