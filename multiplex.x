namespace hogd {

enum MultiplexMessageType {
  MultiplexMessageInvalid = 0,
  MultiplexMessageBatch = 1,
  MultiplexMessageSCP = 2,
};

union MultiplexMessage switch (MultiplexMessageType type)
{
case MultiplexMessageBatch:
  BatchMessage batch;
default:
  void;
};

} // namespace hogd
