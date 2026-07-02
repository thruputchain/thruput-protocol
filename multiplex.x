namespace hogd {

enum MultiplexMessageType {
  MultiplexMessageInvalid = 0,
  MultiplexMessageSubmittedTxs = 1,
  MultiplexMessageBigValue = 2,
  MultiplexMessageSCP = 3,
};

union MultiplexMessage switch (MultiplexMessageType type)
{
case MultiplexMessageSubmittedTxs:
  SubmittedTransactions submitted;
case MultiplexMessageBigValue:
  BigValue big_value;
case MultiplexMessageSCP:
  SCPEnvelope envelope;
default:
  void;
};

} // namespace hogd
