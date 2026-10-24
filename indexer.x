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
  /// No committed record, but a proposer excluded the transaction within the
  /// last few blocks (a two-phase-commit conflict or a refused contract
  /// attachment) and the indexer still holds the diagnostic.
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

/// Max contracts per filter.  Matches Soroban getEvents' limit of 5;
/// designed to be low enough that the merge-walk stays cheap even on
/// degenerate inputs.
const kMaxContractAddressesPerEventFilter = 5;
/// Max filters per query, chosen like `kMaxContractAddressesPerEventFilter`.
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
/// `contract_addresses` AND match the topic constraints.  The indexer has
/// no topic-indexed column family and can't efficiently serve "any
/// contract" scans, so a query with no filters, or with any filter whose
/// contract_addresses is empty, matches nothing: it returns an empty page,
/// or IndexerQueryInvalidCursor if it carries a cursor.  (When such an
/// index is added, the indexer can relax this; the XDR stays the same.)
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
  TransactionHash tx_hash;
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
  /// Malformed, wrong-block, or height-mismatched cursors return
  /// IndexerQueryInvalidCursor. A valid continuation whose block is not yet
  /// indexed returns IndexerQueryHistoryUnavailable.
  PaginationCursor cursor;
  /// Clamped server-side to [1, 200]; 0 means server default (50).
  unsigned int limit;
};

/// Transaction refs in the query's order. Every successful response reports
/// the indexer's current bounds, including empty responses.
struct TransactionRefPage {
  TransactionRefBatch refs;
  PaginationCursor cursor;
  /// Highest block the indexer serves.
  BlockHeight latest_block;
  /// Lowest block the query covers: 1 (the first indexed block) for
  /// get_transactions_by_block, and the indexer's oldest retained block
  /// (today always 0) for get_transactions_by_address.
  BlockHeight oldest_block;
};

/// Backend disposition of a block-explorer page query.  Distinguishes
/// "the query ran and matched nothing" (IndexerQueryOk with an empty
/// page) from "the indexer could not run the query at all", so a
/// broken or still-opening node is not rendered as an empty chain.
enum IndexerQueryOutcome {
  IndexerQueryOk = 0,
  /// The indexer cannot serve the query yet: its database is not open
  /// (still starting up, or shut down), or, for block queries, no block
  /// is indexed yet or the block projection is still being built.
  /// Transient from the cluster's point of view: retry, or ask a healthy
  /// node.
  IndexerQueryNotReady = 1,
  /// Unrecoverable backend failure (corrupt record, storage error).
  /// Details are in the indexer's logs.
  IndexerQueryInternalFailure = 2,
  /// The supplied continuation is malformed, unsupported, or inconsistent
  /// with the query or its indexed block identity/position. Not exhaustion.
  /// No automatic restart is implied. Cursor validation depends on the method;
  /// this outcome does not promise query binding for every cursor format.
  IndexerQueryInvalidCursor = 3,
  /// The indexer cannot serve the history required by a continuation: its
  /// serving watermark is below the cursor's saved bound, or its target block
  /// is not yet indexed. Preserve the cursor; do not silently narrow the walk.
  IndexerQueryHistoryUnavailable = 4
};

union EventPageResult switch (IndexerQueryOutcome outcome) {
case IndexerQueryOk:
  EventPage page;
default:
  void;
};

union TransactionPageResult switch (IndexerQueryOutcome outcome) {
case IndexerQueryOk:
  TransactionPage page;
default:
  void;
};

union TransactionRefPageResult switch (IndexerQueryOutcome outcome) {
case IndexerQueryOk:
  TransactionRefPage page;
default:
  void;
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
    TxInfoResult get_transaction_info(TransactionHash) = 1;

    // The canonical consensus value for a retained, indexed height. Heights
    // outside ready indexed coverage return BlockNotFound. An index that is
    // not ready or has an internal failure returns an x23 SYSTEM_ERR, not a miss.
    BlockLookupResult get_block_by_height(BlockHeight) = 2;

    // Paginated, filtered events query.  A candidate event matches
    // iff it matches at least one EventFilter in the request (OR
    // across filters, AND within each filter).  Supports the wallet
    // "transfers to OR from me" case in a single call.
    EventPageResult get_events(EventQuery) = 3;

    // Paginated transactions, whole-chain, in block order.
    TransactionPageResult get_transactions(TransactionQuery) = 4;

    // Paginated transaction refs whose root invoked address == the query
    // address (account transaction history).  Hydrate via get_transaction_info.
    TransactionRefPageResult get_transactions_by_address(AddressTransactionQuery) = 5;

    // Paginated transaction refs committed at exactly the requested height.
    // Hydrate via get_transaction_info.
    TransactionRefPageResult get_transactions_by_block(BlockTransactionQuery) = 6;
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

/// Canonical committed-block payload returned to the indexer. The durable
/// outbox record stores only `format_version` and `consensus_value`; the two
/// batches live in the block's content-addressed events file, named by
/// `consensus_value.proposal_header.events_hash`, and are reassembled on load.
struct IndexerCommittedBlockPayload {
  unsigned int format_version;
  ConsensusValue consensus_value;
  // Both batches are positionally paired; their order is not significant.
  // Each inner Transaction is bound by consensus_value.proposal_header.txs_hash,
  // while the corresponding event log and nondeterministic proposal data are
  // bound together by consensus_value.proposal_header.events_hash. Both roots
  // are recomputed whenever the payload is loaded from disk. Signature
  // wrappers are intentionally outside both consensus commitments and remain
  // trusted internal payload: any wrapper satisfying the transaction's auth
  // claim is equally valid, so which one a block carries is not observable to
  // anything that validates against the header.
  TxEventLogBatch event_logs;
  ProposedTransactionBatch tx_bodies;
};

struct IndexerCommittedBlockIdentity {
  ConsensusValueHash consensus_hash;
};

struct IndexerCommittedBlock {
  IndexerCommittedBlockPayload payload;
  IndexerCommittedBlockIdentity identity;
};

struct IndexerInitializedProgress {
  IndexerOutboxOrigin origin;
  BlockHeight contiguous_height;
  ConsensusValueHash last_consensus_hash;
};

/// Where the indexer stands, as its pull request states it.
enum IndexerProgressState {
  /// No origin adopted yet. The server answers with the oldest retained
  /// origin, or its first block; never held.
  IndexerProgressUninitialized = 0,
  /// Applied everything through `initialized`; asks what comes next. Answered
  /// at once: the next block, `EventIndexerPullCaughtUp` when there is none,
  /// or a conflict. The first pull of every connection is this, since the
  /// caught-up reply is the indexer's readiness signal.
  IndexerProgressInitialized = 1,
  /// Same cursor, and already answered caught up on this connection. Asks the
  /// server to hold the request until the next publication and answer with
  /// it, so a block is pulled the moment it is committed rather than when the
  /// indexer next asks. Request-only: an indexer never persists this state.
  IndexerProgressCaughtUp = 2
};

union IndexerProgress switch (IndexerProgressState state) {
case IndexerProgressInitialized:
case IndexerProgressCaughtUp:
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

/// The indexer's durable progress is its replay cursor. A lost reply is safe:
/// the next request either repeats the same immutable block or advances from
/// progress already committed by the indexer.
struct EventIndexerPullRequest {
  ProtocolCommit protocol;
  IndexerProgress progress;
};

struct EventIndexerPulledBlock {
  IndexerOutboxOrigin origin;
  IndexerCommittedBlock block;
};

enum EventIndexerPullOutcome {
  EventIndexerPullBlock = 0,
  EventIndexerPullCaughtUp = 1,
  EventIndexerPullNotReady = 2,
  EventIndexerPullMismatchedProtocol = 3,
  EventIndexerPullProgressConflict = 4,
  EventIndexerPullInternalFailure = 5
};

union EventIndexerPullResult switch (EventIndexerPullOutcome outcome) {
case EventIndexerPullBlock:
  EventIndexerPulledBlock pulled_block;
case EventIndexerPullCaughtUp:
  IndexerOutboxOrigin origin;
default:
  IndexerFailureMessage diagnostic;
};

/// A committed block as event_indexer_pull_next_chunked answers it: everything
/// but its event logs and transaction bodies, which the event server has
/// already sent as a run of `chunk_count` EventIndexerBlockChunk calls.
struct EventIndexerChunkedBlock {
  IndexerOutboxOrigin origin;
  unsigned int format_version;
  ConsensusValue consensus_value;
  IndexerCommittedBlockIdentity identity;
  unsigned int chunk_count;
};

/// Outcomes as for `event_indexer_pull_next`.
union EventIndexerChunkedPullResult switch (EventIndexerPullOutcome outcome) {
case EventIndexerPullBlock:
  EventIndexerChunkedBlock chunked_block;
case EventIndexerPullCaughtUp:
  IndexerOutboxOrigin origin;
default:
  IndexerFailureMessage diagnostic;
};

/// One chunk of a pulled block's two positionally paired batches. The chunks
/// of a block follow the KeyChangeChunk convention: every chunk carries the
/// same chunk_count, each index in [0, chunk_count) is sent exactly once, the
/// chunks may be sent concurrently and arrive in any order, and a block with
/// no transactions is a run of one empty chunk. Concatenated in index order,
/// the chunks' batches are the block's `event_logs` and `tx_bodies`.
struct EventIndexerBlockChunk {
  BlockHeight block_height;
  IndexerCommittedBlockIdentity identity;
  unsigned int chunk_index;
  unsigned int chunk_count;
  TxEventLogBatch event_logs;
  ProposedTransactionBatch tx_bodies;
};

struct IndexerTxFailureNotice {
  TransactionHash tx_hash;
  TxFailureDiagnostic diagnostic;
};

typedef IndexerTxFailureNotice IndexerTxFailureNoticeBatch<256>;

// The indexer pulls durable blocks and best-effort diagnostics from the event
// server. Diagnostics use a separate bounded reply so they never reduce the
// maximum committed-block reply size.
program EventIndexer
{
  version EventIndexer1
  {
    EventIndexerPullResult event_indexer_pull_next(
      EventIndexerPullRequest) = 10;
    IndexerTxFailureNoticeBatch event_indexer_pull_tx_failures(void) = 11;

    // event_indexer_pull_next for a block of any size. The same request,
    // outcomes and parking, but a block's event logs and bodies do not travel
    // in the reply: before replying, the event server sends them as a run of
    // indexer_event_block_chunk calls back over the same connection, to the
    // IndexerEvent1 program the indexer serves there. Every chunk has been
    // acknowledged by the time the reply arrives, so the reply completes the
    // block. A connection lost part way loses the attempt; the indexer pulls
    // the block again from its durable progress.
    EventIndexerChunkedPullResult event_indexer_pull_next_chunked(
      EventIndexerPullRequest) = 12;
  } = 1;
}
= 0x4321aaac;

// Served by the indexer on its own connection to the event server, which
// calls it to deliver the chunks of a block event_indexer_pull_next_chunked is
// answering.
program IndexerEvent
{
  version IndexerEvent1
  {
    void indexer_event_block_chunk(EventIndexerBlockChunk) = 1;
  } = 1;
}
= 0x4321aaad;

} // namespace hogd
