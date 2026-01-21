%#include "event.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {

// Clients (e.g., block explorer GUIs) use this API to retrieve data from the
// indexer.
program Indexer
{
  version Indexer1
  {
    TxEventLog get_events_for_transaction(SignedTransactionHash) = 0;
  } = 1;
}
= 0x4321aaaa;

typedef TxEventLogBatch TxEventLog<>;

// The event server uses this API to communicate with the indexer.
program IndexerEvent
{
  version IndexerEvent1
  {
    TxEventLog indexer_event_process_events() = 0;
  } = 1;
}
= 0x4321aaab;

// The indexer uses this API to communicate with the event server.
program EventIndexer
{
  version EventIndexer1
  {
    TxEventLog event_indexer_intro() = 0;
  } = 1;
}
= 0x4321aaac;

} // namespace hogd
