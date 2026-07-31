// clang-format off
%#include "consensus.hh"
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

enum BlockLookupOutcome {
  BlockFound = 0,
  BlockNotFound = 1
};

union BlockLookupResult switch (BlockLookupOutcome outcome) {
case BlockFound:
  ConsensusValue value;
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
/// executed in. Returned by transaction-ref queries; hydrate the full body
/// via `get_transaction_info`.
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

/// `get_transactions_by_block` request. Returns transactions committed at
/// exactly `height`, ordered lexicographically by their 32 unsigned hash bytes.
struct BlockTransactionQuery {
  BlockHeight height;
  IterationOrder order;
  /// Empty on the initial call. Non-empty to continue at the same height;
  /// `order` is ignored when a cursor is supplied because the cursor carries it.
  /// Malformed, stale, or height-mismatched cursors produce an empty page with
  /// an empty cursor.
  PaginationCursor cursor;
  /// Clamped server-side to [1, 200]; 0 means server default (50).
  unsigned int limit;
};

/// Transaction refs in the query's order. Every successful response reports
/// the indexer's current bounds, including empty responses.
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
    IndexerBlockExplorerIntroOutcome indexer_block_explorer_intro(ProtocolCommit) = 0;
    TxInfoResult get_transaction_info(SignedTransactionHash) = 1;

    // The canonical consensus value for a retained, indexed height. Unknown,
    // future, and unavailable heights return BlockNotFound; backend failures
    // remain RPC errors.
    BlockLookupResult get_block_by_height(BlockHeight) = 2;

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

    // Paginated transaction refs committed at exactly the requested height.
    // Hydrate via get_transaction_info.
    TransactionRefPage get_transactions_by_block(BlockTransactionQuery) = 6;
  } = 1;
}
= 0x4321aaaa;

typedef TxEventLog TxEventLogBatch<>;

/// Immutable identity of one protocol epoch in the event service's durable
/// indexer outbox. The first committed block in the epoch is `first_height`
/// and links to `first_prev_hash`.
struct IndexerOutboxOrigin {
  ProtocolCommit protocol;
  unsigned hyper epoch_sequence;
  BlockHeight first_height;
  ConsensusValueHash first_prev_hash;
};

/// Canonical durable outbox payload. This exact XDR value is hashed for
/// `payload_digest`, stored in the private outbox record, and delivered to the
/// indexer so both sides use one content identity.
struct IndexerCommittedBlockPayload {
  unsigned int format_version;
  ConsensusValue consensus_value;
  ProposalTxs proposal_txs;
  TxEventLogBatch event_logs;
  ProposedTransactionBatch tx_bodies;
};

struct IndexerCommittedBlockIdentity {
  ConsensusValueHash consensus_hash;
  SHA256Hash payload_digest;
};

struct IndexerCommittedBlock {
  IndexerCommittedBlockPayload payload;
  IndexerCommittedBlockIdentity identity;
};

struct IndexerInitializedProgress {
  IndexerOutboxOrigin origin;
  BlockHeight contiguous_height;
  ConsensusValueHash last_consensus_hash;
  SHA256Hash last_payload_digest;
};

enum IndexerProgressState {
  IndexerProgressUninitialized = 0,
  IndexerProgressInitialized = 1
};

union IndexerProgress switch (IndexerProgressState state) {
case IndexerProgressInitialized:
  IndexerInitializedProgress initialized;
default:
  void;
};

typedef string IndexerFailureMessage<1024>;

enum IndexerEpochOutcome {
  IndexerEpochInitialized = 0,
  IndexerEpochUnchanged = 1,
  IndexerEpochConflict = 2,
  IndexerEpochInternalFailure = 3
};

union IndexerEpochResult switch (IndexerEpochOutcome outcome) {
case IndexerEpochInitialized:
case IndexerEpochUnchanged:
  IndexerInitializedProgress progress;
default:
  IndexerFailureMessage diagnostic;
};

struct IndexerHeightGap {
  BlockHeight expected_height;
};

enum IndexerBlockApplyOutcome {
  IndexerBlockApplied = 0,
  IndexerBlockDuplicate = 1,
  IndexerBlockGap = 2,
  IndexerBlockOriginMismatch = 3,
  IndexerBlockContentConflict = 4,
  IndexerBlockInternalFailure = 5
};

union IndexerBlockApplyResult switch (IndexerBlockApplyOutcome outcome) {
case IndexerBlockApplied:
case IndexerBlockDuplicate:
  IndexerInitializedProgress progress;
case IndexerBlockGap:
  IndexerHeightGap gap;
default:
  IndexerFailureMessage diagnostic;
};

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

  version IndexerEvent2
  {
    IndexerProgress indexer_event_get_progress(void) = 10;
    IndexerEpochResult indexer_event_initialize_epoch(IndexerOutboxOrigin) = 11;
    IndexerBlockApplyResult indexer_event_apply_committed_block(
        IndexerOutboxOrigin, IndexerCommittedBlock) = 12;

    // Diagnostics remain best-effort and are independent of durable block
    // acknowledgement.
    void indexer_event_report_tx_failure_v2(SignedTransactionHash,
                                            TxFailureDiagnostic) = 13;
  } = 2;
}
= 0x4321aaab;

struct IndexerCard {
  ProtocolCommit protocol;
  ServerAddress address_for_event;
};

/// V2 registration is bound to one indexer process generation and the durable
/// progress observed immediately before registration. A later successful
/// registration replaces the event service's single receiver slot.
struct IndexerCardV2 {
  ProtocolCommit protocol;
  UPID generation;
  // Absent for the first durable indexer session. A new session may replace
  // only the event slot named by this predecessor. Exact-generation retries
  // remain heartbeats, including retries after an accepted response was lost.
  UPID *predecessor_generation;
  ServerAddress address_for_event;
  IndexerProgress progress;
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

enum EventIndexerRegistrationOutcome {
  EventRegistrationAccepted = 0,
  EventRegistrationMismatchedProtocol = 1,
  EventRegistrationConnectFailed = 2,
  EventRegistrationOriginUnavailable = 3,
  EventRegistrationProgressConflict = 4,
  EventRegistrationReplayFailed = 5,
  // This process generation previously owned the slot but was superseded by a
  // later registration. It cannot reclaim ownership by retrying.
  EventRegistrationStaleGeneration = 6
};

// The indexer uses this API to communicate with the event server.
program EventIndexer
{
  version EventIndexer1
  {
    EventIndexerIntroOutcome event_indexer_intro(IndexerCard) = 0;
  } = 1;

  version EventIndexer2
  {
    EventIndexerRegistrationOutcome event_indexer_register(IndexerCardV2) = 10;
    EventIndexerRegistrationOutcome event_indexer_probe(UPID) = 11;
  } = 2;
}
= 0x4321aaac;

} // namespace hogd
