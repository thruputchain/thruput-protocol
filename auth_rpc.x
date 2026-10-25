%#include "auth_card.hh"
%#include "sched_db.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {

enum AuthErrorCode {
  kAuthSuccess = 0,
  kAuthFailed = 1,
  // The query is for a block height that is not the most recent committed block height.
  // This can happen if a query is made for an old block height,
  // or if (concurrent with the query) a block commits and updates to the auth data begin to stream in.
  // The verification can be retried in either case.
  // TODO(geoff): We could switch this around, to retry at the higher block height.
  kAuthStaleBlockHeight = 2,
  // Either an internal auth error or forwarded from an internal DB error
  kAuthInternal = 3
};

typedef AuthErrorCode AuthErrorCodeBatch<>;

program AuthMempool {
  version AuthMempool1 {

    // Verify a list of transactions.  This version returns a result for each transaction.
    // The BlockHeight is the height of the most recently committed block,
    // i.e. the block height of the block that produced the snapshot auth data against which
    // the transactions are to be verified.
    AuthErrorCodeBatch authmempool_verify_transactions(BlockHeight, SignedTransactionBatch) = 2;

    // Verify a batch of transactions.  This version returns a single result for the batch,
    // i.e. are all correct or is there at least one invalid transaction?
    // This version should be called when validating a proposal, in which if even one
    // transaction is invalid then the whole block can be rejected.
    // This version can use batch verification to speed up the verification.
    AuthErrorCode authmempool_verify_batch(BlockHeight, SignedTransactionBatch) = 3;
  }
  = 1;
}
= 0x8aa87aa7;

struct KeyChange {
  ContractAddress address;
  AddressAuthData *auth_data;
};
typedef KeyChange KeyChangeBatch<>;

// A committed block's auth-data changes travel as a run of chunks, each a
// KeyChangeChunk, from hog_db to the auth server and on from the auth server
// to the mempool, because the one-record form grew with the number of
// accounts whose auth data a block changed (hogd#3146). The sender chooses
// the chunk size; the wire bounds a chunk only by the link's record cap. The
// chunks of a run may be sent concurrently and over several connections, so
// they can arrive in any order, and a sender may have the runs of several
// heights in flight at once, so the chunks of different heights can
// interleave. A receiver treats a height's changes as complete only once
// every chunk of its run has arrived, and applies heights in order.
struct KeyChangeChunk {
  // The height of the block that made these changes.
  BlockHeight height;
  // This chunk's position in the height's run, from 0, and the run's length.
  // Every chunk of a run carries the same chunk_count, and each index in
  // [0, chunk_count) is sent exactly once. A block that changed no auth data
  // is a run of one empty chunk, so every committed block still sends a run
  // and each receiver's height advances with every block.
  unsigned int chunk_index;
  unsigned int chunk_count;
  KeyChange changes<>;
};

program AuthDB {
  version AuthDB1 {
    // Retired number, never to be reused, so that a peer built against it
    // fails to dispatch rather than misparse a newer payload:
    //   1: authdb_forward_key_changes(BlockHeight, KeyChangeBatch), a block's
    //      auth-data changes in one unbounded record, which a block that
    //      changes enough accounts' auth data grows past any single-record
    //      cap (hogd#3146).

    // Deliver one chunk of a committed block's auth-data changes to the auth
    // server.
    void authdb_forward_key_changes_chunk(KeyChangeChunk) = 2;
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

union DBAuthIntroResult switch (DBAuthIntroOutcome outcome) {
case kIntroSuccess:
  BlockHeight current_height;
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

    // Introduce an auth server to a db shard,
    // and subscribe to updates to auth data
    DBAuthIntroResult dbauth_intro(AuthCard) = 2;
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
    // Register an auth server with the mempool. The mempool serves the
    // coordinator only once an auth server has registered, so an auth server
    // registers only after it has subscribed to the db's auth-data changes
    // (dbauth_intro), finding the db shards with mempoolauth_get_auth_info.
    // Otherwise a block could commit before the subscription, and its changes
    // would never reach the mempool (hogd#1927). The result repeats what
    // mempoolauth_get_auth_info returned.
    IntroAuthResult mempoolauth_intro_auth(AuthCard) = 0;

    // Retired number, never to be reused, so that a peer built against it
    // fails to dispatch rather than misparse a newer payload:
    //   1: mempoolauth_auth_data_changed(BlockHeight, KeyChangeBatch), a
    //      block's auth-data changes in one unbounded record (hogd#3146).

    // Deliver one chunk of a committed block's auth-data changes from the auth
    // server to the mempool. The auth server sends a height's run only after
    // it has applied the whole height itself.
    void mempoolauth_auth_data_changed_chunk(KeyChangeChunk) = 2;

    // Return the db shards and the network hash, which an auth server needs
    // to subscribe to the db before it registers. Unlike
    // mempoolauth_intro_auth, this does not register the auth server.
    IntroAuthResult mempoolauth_get_auth_info(ProtocolCommit) = 3;
  }
  = 1;
} = 0x8aa87aaa;

} // namespace hogd
