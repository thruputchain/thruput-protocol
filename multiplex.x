namespace hogd {

enum MultiplexMessageType {
  MultiplexMessageInvalid = 0,
  MultiplexMessageSubmittedTxs = 1,
  MultiplexMessageConsensusBasis = 2,
  MultiplexMessageSCP = 3,
};

union MultiplexMessage switch (MultiplexMessageType type)
{
case MultiplexMessageSubmittedTxs:
  SubmittedTransactions submitted;
case MultiplexMessageConsensusBasis:
  ConsensusValueWithBasis consensus_value_with_basis;
case MultiplexMessageSCP:
  SCPEnvelope envelope;
default:
  void;
};

} // namespace hogd
