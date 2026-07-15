// clang-format off
%#include "db_conflict.hh"
%#include "event.hh"
%#include "network.hh"
%#include "pagination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

struct TxInfo {
  // The height of the block the tx was executed in.
  BlockHeight height;
  // The full transaction body (signed tx + nondeterministic data), as
  // forwarded by the event server and stored in the indexer.
  ProposedTransaction tx;
  TxEventLog events;
};

enum TxInfoOutcome {
  TxInfoFound = 0,
  TxInfoNotFound = 1,
  /// No committed record, but the transaction failed nondeterministically
  /// within the last few blocks and the indexer still holds the diagnostic.
  /// Best-effort and advisory: reports are dropped freely under load, only
  /// the proposing node's indexers hear them, and a later retry of the same
  /// tx may still commit (at which point TxInfoFound wins). Absence of this
  /// outcome proves nothing.
  TxInfoRecentFailure = 2
};

union TxInfoResult switch (TxInfoOutcome outcome) {
case TxInfoFound:
  TxInfo info;
case TxInfoRecentFailure:
  TxFailureDiagnostic recent_failure;
default:
  void;
};

typedef IdentifiedEvent IdentifiedEventBatch<>;

typedef TxInfo TxInfoBatch<>;

/// Max contracts per filter and max filters per query.  Matches Soroban
/// getEvents' limit of 5; designed to be low enough that the merge-walk
/// stays cheap even on degenerate inputs.
const kMaxContractAddressesPerEventFilter = 5;
const kMaxEventFiltersPerQuery = 5;

typedef ContractAddress ContractAddressList<kMaxContractAddressesPerEventFilter>;

/// Positional topic filter.  For each topic position (0, 1, 2):
///   - An empty list means "match anything at this position."
///   - A non-empty list means "match if the event's topic at this
///     position is in this list."  OR within a position, AND across
///     positions.
///
/// Partial match: a filter that specifies only topic0 matches events
/// with more topics.  Extra topics on the event past the filter's
/// specified positions are ignored.  (This is the ethereum getLogs /
/// stellar-rpc post-#358 semantics.)
struct EventTopicFilter {
  Topic topic0<>;
  Topic topic1<>;
  Topic topic2<>;
};

/// A single event-filter predicate: events must be emitted by one of
/// `contract_addresses` AND match the topic constraints.  Required
/// non-empty contract_addresses — the indexer has no topic-indexed
/// column family and can't efficiently serve "any contract" scans.
/// (When such an index is added, the gateway relaxes the non-empty
/// check; the XDR stays the same.)
struct EventFilter {
  ContractAddressList contract_addresses;
  EventTopicFilter topics;
};

typedef EventFilter EventFilterList<kMaxEventFiltersPerQuery>;

/// `get_events` request.  A candidate event matches the query iff it
/// matches at least one `EventFilter` in `filters` (OR across filters,
/// AND within each filter).
struct EventQuery {
  EventFilterList filters;
  IterationOrder order;
  BlockAnchor anchor;
  /// Empty on the initial call.  Non-empty to continue where a
  /// previous response left off; `order` and `anchor` in the request
  /// are ignored when a cursor is supplied — the cursor carries them.
  PaginationCursor cursor;
  /// Clamped server-side to [1, 200]; 0 means server default (50).
  unsigned int limit;
};

/// `get_events` response.
struct EventPage {
  /// Matched events in the requested order.  May be empty even when
  /// `cursor` is non-empty: the filter was selective and the current
  /// scan window produced no matches, so the client should keep
  /// paginating.  Empty events + empty cursor = stream exhausted.
  IdentifiedEventBatch events;

  /// Empty when the stream has been exhausted in the requested
  /// direction.  Non-empty: pass back in the next call's `cursor`
  /// argument.
  PaginationCursor cursor;

  /// Highest block height the indexer has processed at response time.
  /// Clients compare to the heights on their last-seen events to
  /// decide whether they're caught up.
  BlockHeight latest_block;

  /// Oldest block height the indexer still retains data for at
  /// response time.  Today always 0; once retention/pruning lands
  /// this is the lower bound below which queries return empty
  /// regardless of anchor.
  BlockHeight oldest_block;
};

/// `get_transactions` request.  Whole-chain walk in `order` from `anchor`.
/// There is no address filter here — use `get_transactions_by_address` for
/// per-account (root invoked address) transaction history.
struct TransactionQuery {
  IterationOrder order;
  BlockAnchor anchor;

  /// Empty on the initial call.  Non-empty to continue where a previous
  /// response left off; `order` and `anchor` in the request are ignored
  /// when a cursor is supplied — the cursor carries them.
  PaginationCursor cursor;

  /// Clamped server-side to [1, 200]; 0 means server default (50).
  unsigned int limit;
};

/// `get_transactions` response.
struct TransactionPage {
  /// Matched transactions in the requested order.  May be empty even
  /// when `cursor` is non-empty: the current scan window produced no
  /// matches, so the client should keep paginating.  Empty
  /// transactions + empty cursor = stream exhausted.
  TxInfoBatch transactions;

  /// Empty when the stream has been exhausted in the requested
  /// direction.  Non-empty: pass back in the next call's `cursor`
  /// argument.
  PaginationCursor cursor;

  /// Highest block height the indexer has processed at response time.
  /// Clients compare to the heights on their last-seen transactions to
  /// decide whether they're caught up.
  BlockHeight latest_block;

  /// Oldest block height the indexer still retains data for at
  /// response time.  Today always 0; once retention/pruning lands
  /// this is the lower bound below which queries return empty
  /// regardless of anchor.
  BlockHeight oldest_block;
};

/// Lightweight reference to a transaction: its hash plus the block it
/// executed in.  Returned by `get_transactions_by_address`; hydrate the
/// full body via `get_transaction_info`.
struct TransactionRef {
  SignedTransactionHash tx_hash;
  BlockHeight height;
};

typedef TransactionRef TransactionRefBatch<>;

/// `get_transactions_by_address` request.  Walked in `order` from `anchor`,
/// returning transactions whose ROOT invocation targets `address` (i.e. the
/// account's transaction history).
struct AddressTransactionQuery {
  ContractAddress address;
  IterationOrder order;
  BlockAnchor anchor;
  /// Empty on the initial call.  Non-empty to continue; `order`/`anchor`
  /// are ignored when a cursor is supplied.
  PaginationCursor cursor;
  /// Clamped server-side to [1, 200]; 0 means server default (50).
  unsigned int limit;
};

/// `get_transactions_by_address` response: transaction refs in `order`.
struct TransactionRefPage {
  TransactionRefBatch refs;
  PaginationCursor cursor;
  BlockHeight latest_block;
  BlockHeight oldest_block;
};

enum IndexerBlockExplorerIntroOutcome {
  IntroSuccess = 0,
  IntroMismatchedProtocol = 1
};

// API exposed from the Indexer for the public RPC Gateway.
program IndexerBlockExplorer
{
  version IndexerBlockExplorer1
  {
    IndexerBlockExplorerIntroOutcome indexer_block_explorer_intro(Protocol) = 0;
    TxInfoResult get_transaction_info(SignedTransactionHash) = 1;

    // Paginated, filtered events query.  A candidate event matches
    // iff it matches at least one EventFilter in the request (OR
    // across filters, AND within each filter).  Supports the wallet
    // "transfers to OR from me" case in a single call.
    EventPage get_events(EventQuery) = 3;

    // Paginated transactions, whole-chain, in block order.
    TransactionPage get_transactions(TransactionQuery) = 4;

    // Paginated transaction refs whose root invoked address == the query
    // address (account transaction history).  Hydrate via get_transaction_info.
    TransactionRefPage get_transactions_by_address(AddressTransactionQuery) = 5;
  } = 1;
}
= 0x4321aaaa;

typedef TxEventLog TxEventLogBatch<>;

// The event server uses this API to communicate with the indexer.
program IndexerEvent
{
  version IndexerEvent1
  {
    // Event logs and the full transaction bodies for a committed block,
    // forwarded together and index-aligned: the body at position i is the
    // transaction whose event log is at position i.  The event server pairs
    // them at emission, so the indexer never has to re-match bodies to events.
    //
    // The bodies travel beside the event log (which is hashed into the
    // consensus event trie) rather than inside it; the indexer stores them for
    // block-explorer transaction lookups.
    void indexer_event_process_events(BlockHeight, TxEventLogBatch,
                                      ProposedTransactionBatch) = 0;

    // Best-effort relay (from the event server) of a transaction that failed
    // nondeterministically at proposal time. The indexer caches it briefly so
    // get_transaction_info can explain the failure; it may drop reports
    // freely (cache full) and expires them a few blocks later.
    void indexer_event_report_tx_failure(SignedTransactionHash,
                                         TxFailureDiagnostic) = 1;
  } = 1;
}
= 0x4321aaab;

struct IndexerCard {
  Protocol protocol;
  ServerAddress address_for_event;
};

enum EventIndexerIntroOutcome {
  EventIntroSuccess = 0,
  // The indexer advertised a protocol string the event server does not speak.
  EventIntroMismatchedProtocol = 1,
  // The event server could not dial the indexer's advertised address_for_event
  // (e.g. a bind/advertise mismatch or a refused connection). The registration
  // is rejected rather than silently accepted, so the indexer does not mark
  // itself healthy while the event server has no client for it.
  EventIntroConnectFailed = 2
};

// The indexer uses this API to communicate with the event server.
program EventIndexer
{
  version EventIndexer1
  {
    EventIndexerIntroOutcome event_indexer_intro(IndexerCard) = 0;
  } = 1;
}
= 0x4321aaac;

} // namespace hogd
