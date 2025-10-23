namespace hogd {

enum MultiplexMessageType {
  MultiplexMessageInvalid = 0,
  MultiplexMessageSubmittedTxs = 1,
  MultiplexMessageConsensusValue = 2,
  MultiplexMessageSCP = 3,
};

union MultiplexMessage switch (MultiplexMessageType type)
{
case MultiplexMessageSubmittedTxs:
  SubmittedTransactions submitted;
case MultiplexMessageConsensusValue:
  ConsensusValue consensus_value;
case MultiplexMessageSCP:
  SCPEnvelope envelope;
default:
  void;
};

} // namespace hogd
