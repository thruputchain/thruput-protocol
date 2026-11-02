namespace hogd {

enum MultiplexMessageType {
  MultiplexMessageInvalid = 0,
  MultiplexMessageSubmittedTxs = 1,
  MultiplexMessageConsensusBasis = 2,
  MultiplexMessageEnvelope = 3,
};

union MultiplexMessage switch (MultiplexMessageType type)
{
case MultiplexMessageSubmittedTxs:
  SubmittedTransactions submitted;
case MultiplexMessageConsensusBasis:
  ConsensusBasis basis;
case MultiplexMessageEnvelope:
  BristleconeEnvelope envelope;
default:
  void;
};

} // namespace hogd
