%#include "auth_card.hh"
%#include "rpc_types.hh"
%#include "sched_db.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {

enum AuthErrorCode {
  kAuthSuccess = 0,
  kAuthFailed = 1,
  // The requested parent state is no longer available in the single-version
  // backend, including when a DB commit races verification. Retrying must use
  // a context opened against the new parent, never silently change the parent
  // of an existing context.
  kAuthStaleBlockHeight = 2,
  // Either an internal auth error or forwarded from an internal DB error
  kAuthInternal = 3,
  // The verification context is unknown, closing, closed, or abandoned.
  kAuthBadBlockID = 4
};

typedef AuthErrorCode AuthErrorCodeBatch<>;

program AuthMempool {
  version AuthMempool1 {
    // Block IDs are the scheduler's IDs, shared with DB and executor.
    // Every verification in a context uses the parent's end-of-block auth
    // state. Changes made by this block affect its children, not its own
    // verification. A context never switches to a newer parent implicitly.
    //
    // Initially only the committed DB tip is a supported parent. Several
    // candidate blocks may share it; advancing the tip makes their old parent
    // state unavailable. The selected block may still complete commit below.
    // Supporting closed, uncommitted parents requires DB multiversion reads.
    //
    // Retired procedures: 2 and 3 verified by BlockHeight. Use new numbers
    // because a height and a BlockID have different meanings despite both
    // occupying eight bytes on the wire.

    // Open a context: first argument is the parent ID, second is the new ID.
    // The caller must allocate a fresh ID, including after commit or abandon.
    // Returns kRPCBadBlockID for an unavailable parent or an existing context.
    RPCError authmempool_open_block(BlockID, BlockID) = 10;

    // Verify transactions against the open context identified by BlockID.
    // Returns one result per input transaction, in input order. A context
    // error is returned for every input; an empty input returns an empty list.
    AuthErrorCodeBatch authmempool_verify_transactions(BlockID, SignedTransactionBatch) = 20;

    // Verify a proposal's transactions, returning success only if all pass.
    // The context must be open even for an empty batch. This may use batch
    // signature verification.
    AuthErrorCode authmempool_verify_batch(BlockID, SignedTransactionBatch) = 21;

    // Stop accepting verification and wait for accepted requests to finish.
    // Retain the context for commit or abandon. Does not wait for DB commit
    // or key-change notifications, and does not certify that all requests
    // passed: the caller must check their individual results.
    RPCError authmempool_close_block(BlockID) = 30;

    // Called for the finalized block after close. The scheduler must also
    // issue DB commit independently; this call may overlap it. Wait until
    // the matching block's complete DB update run has been applied locally,
    // then retire the context. The DB stream remains the authority for
    // committed auth data; this call does not apply the changes again.
    // Completion does not wait for the mempool's key-change callback to be
    // acknowledged. If a different block commits at the expected height,
    // return kRPCBadBlockID instead of waiting for this candidate.
    RPCError authmempool_commit_block(BlockID) = 31;

    // Discard an open or closed context. Reject new verification and drain
    // accepted requests before releasing it. Never changes committed state.
    RPCError authmempool_abandon_block(BlockID) = 40;

    // Lifecycle calls return kRPCBadBlockID for unknown IDs or invalid state
    // transitions. Close and abandon do not require the parent to remain
    // readable, so stale contexts can still be drained and released.
  }
  = 1;
}
= 0x8aa87aa7;

struct KeyChange {
  ContractAddress address;
  AddressAuthData *auth_data;
};
typedef KeyChange KeyChangeBatch<>;

// A committed block's auth-data changes reach the auth server as a run of
// chunks, each a KeyChangeChunk, because the one-record form grew with the
// number of accounts whose auth data a block changed (hogd#3146). hog_db
// chooses the chunk size; the wire bounds a chunk only by the link's record
// cap. The chunks of a run may be sent concurrently and over several
// connections, so they can arrive in any order, and hog_db may have the runs
// of several heights in flight at once, so the chunks of different heights
// can interleave. The auth server treats a height's changes as complete only
// once every chunk of its run has arrived, and applies heights in order.
// The block ID must agree across the entire run and identifies the candidate
// selected by DB commit. Notifications remain committed-only.
struct KeyChangeChunk {
  BlockID block_id;
  // The height of the block that made these changes.
  BlockHeight height;
  // This chunk's position in the height's run, from 0, and the run's length.
  // Every chunk of a run carries the same chunk_count, and each index in
  // [0, chunk_count) is sent exactly once. A block that changed no auth data
  // is a run of one empty chunk, so every committed block still sends a run
  // and the auth server's height advances with every block.
  unsigned int chunk_index;
  unsigned int chunk_count;
  KeyChange changes<>;
};

program AuthDB {
  version AuthDB1 {
    // Retired numbers, never to be reused, so that a peer built against them
    // fails to dispatch rather than misparse a newer payload:
    //   1: authdb_forward_key_changes(BlockHeight, KeyChangeBatch), a block's
    //      auth-data changes in one unbounded record, which a block that
    //      changes enough accounts' auth data grows past any single-record
    //      cap (hogd#3146).
    //   2: authdb_forward_key_changes_chunk without a BlockID.

    // Deliver one chunk of a committed block's auth-data changes to the auth
    // server.
    void authdb_forward_key_changes_chunk(KeyChangeChunk) = 3;
  }
  = 1;
}
= 0x8aa87aa8;

enum DBAuthError {
  kDBAuthSuccess = 0,
  kDBAuthNotFound = 1,
  kDBAuthStaleBlockHeight = 2,
  kDBAuthInternal = 3
};

union DBAuthResult switch (DBAuthError error) {
case kDBAuthSuccess:
  AddressAuthData auth_data;
default:
  void;
};

enum DBAuthIntroOutcome {
  kIntroSuccess = 0,
  kIntroFailure = 1
};

// Identifies the committed state available for opening auth contexts and for
// the existing height-based DB lookups. At height -1 the DB is uninitialized;
// block_id is ignored and no auth context can be opened.
struct DBAuthTip {
  BlockID block_id;
  BlockHeight height;
};

union DBAuthIntroResult switch (DBAuthIntroOutcome outcome) {
case kIntroSuccess:
  DBAuthTip tip;
default:
  void;
};

typedef DBAuthResult DBAuthResultBatch<>;

program DBAuth {
  version DBAuth1 {
    // Get the auth data for a single address.
    // If some block concurrently commits which modifies the auth data,
    // then this call can return kDBAuthStaleBlockHeight.
    DBAuthResult authdb_get_auth_data(BlockHeight, ContractAddress) = 0;
    // Get the auth data for a batch of addresses.
    DBAuthResultBatch authdb_get_auth_data_batch(BlockHeight, ContractAddressBatch) = 1;

    // Introduce an auth server and subscribe to committed auth updates.
    // The returned tip and subsequent update runs must leave no gap. Updates
    // may race the reply; a late reply must not overwrite a newer applied tip.
    // Retired procedure 2 returned only a height, without the committed ID.
    DBAuthIntroResult dbauth_intro(AuthCard) = 3;
  }
  = 1;
}
= 0x8aa87aa9;

enum IntroAuthOutcome {
  kSuccess = 0,
  kFailure = 1
};

struct MempoolAuthIntroSuccess {
  ShardCard shards<>;
  NetworkHash network_hash;
};

union IntroAuthResult switch (IntroAuthOutcome outcome)
{
case kSuccess:
  MempoolAuthIntroSuccess success;
default:
  void;
};

program MempoolAuth {
  version MempoolAuth1 {
    IntroAuthResult mempoolauth_intro_auth(AuthCard) = 0;
    // Forward updated key changes from the auth server to the mempool.
    void mempoolauth_auth_data_changed(BlockHeight, KeyChangeBatch) = 1;
  }
  = 1;
} = 0x8aa87aaa;

} // namespace hogd
