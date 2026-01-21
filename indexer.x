// clang-format off
%#include "event.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct TxInfo {
  // The height of the block the tx was executed in.
  BlockHeight height;
  TxEventLog events;
};

enum TxInfoOutcome {
  TxInfoFound = 0,
  TxInfoNotFound = 1
};

union TxInfoResult switch (TxInfoOutcome outcome) {
case TxInfoFound:
  TxInfo info;
default:
  void;
};

// Clients (e.g., block explorer GUIs) use this API to retrieve data from the
// indexer.
program Indexer
{
  version Indexer1
  {
    TxInfoResult get_transaction_info(SignedTransactionHash) = 0;
  } = 1;
}
= 0x4321aaaa;

typedef TxEventLog TxEventLogBatch<>;

// The event server uses this API to communicate with the indexer.
program IndexerEvent
{
  version IndexerEvent1
  {
    void indexer_event_process_events(BlockHeight, TxEventLogBatch) = 0;
  } = 1;
}
= 0x4321aaab;

struct IndexerCard {
  Protocol protocol;
  ServerAddress address_for_event;
};

// The indexer uses this API to communicate with the event server.
program EventIndexer
{
  version EventIndexer1
  {
    void event_indexer_intro(IndexerCard) = 0;
  } = 1;
}
= 0x4321aaac;

} // namespace hogd
