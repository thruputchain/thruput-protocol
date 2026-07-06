namespace hogd {

enum MultiplexMessageType {
  MultiplexMessageInvalid = 0,
  MultiplexMessageSubmittedTxs = 1,
  MultiplexMessageProposal = 2,
  MultiplexMessageSCP = 3,
};

union MultiplexMessage switch (MultiplexMessageType type)
{
case MultiplexMessageSubmittedTxs:
  SubmittedTransactions submitted;
case MultiplexMessageProposal:
  Proposal proposal;
case MultiplexMessageSCP:
  SCPEnvelope envelope;
default:
  void;
};

} // namespace hogd
