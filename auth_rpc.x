%#include "auth_card.hh"
%#include "sched_db.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {


enum AuthResult {
  kAuthSuccess = 0,
  kAuthBatchFailed = 1,
  kAuthStaleBlockHeight = 2,
};

typedef AuthResult AuthResultBatch<>;

program AuthMempool {
  version AuthMempool1 {
    // Notify the mempool auth server that a block has been committed.
    //
    // When this is called, the auth server waits start verifying transactions for the new block
    // until it receives a batch of key changes from each shard of the db.
    // 
    // If this is called concurrently with a call to authmempool_verify*,
    // then those calls may return verification results based on the block id supplied to those calls,
    // or may return kAuthStaleBlockHeight.
    //
    // Note that all of the operations on the AuthMempool server take BlockHeight, not BlockID.
    // The auth service deals only in _committed_ blocks.  
    void authmempool_notify_commit(BlockHeight) = 0;

    // Verify a transaction's auth data.
    // The BlockHeight is the height of the most recently committed block,
    // i.e. the block height of the block that produced the snapshot auth data against which 
    // the transaction is to be verified.
    AuthResult authmempool_verify_transaction(BlockHeight, SignedTransaction) = 1;
    // Verify a list of transactions.  This version returns a result for each transaction,
    // and is equivalent to calling authmempool_verify_transaction for each transaction in the list.
    AuthResultBatch authmempool_verify_transactions(BlockHeight, SignedTransactionBatch) = 2;

    // Verify a batch of transactions.  This version returns a single result for the batch,
    // i.e. are all correct or is there at least one invalid transaction?
    // This version should be called when validating a nomination, in which if even one
    // transaction is invalid then the whole block can be rejected.
    // This version can use batch verification to speed up the verification.
    AuthResult authmempool_verify_batch(BlockHeight, SignedTransactionBatch) = 3;
  }
  = 1;
}
= 0x8aa87aa7;

struct KeyChange {
  ContractAddress address;
  AccountAuthData auth_data;
};
typedef KeyChange KeyChangeBatch<>;

program AuthDB {
  version AuthDB1 {
    // Forward updated key changes to the auth server 
    void authdb_forward_key_changes(BlockHeight, KeyChangeBatch) = 1;
  }
  = 1;
}
= 0x8aa87aa8;

enum DBAuthError {
  kDBAuthSuccess = 0,
  kDBAuthNotFound = 1,
  kDBAuthStaleBlockHeight = 2,
  kDBAuthInternal = 3,
};

union DBAuthResult switch (DBAuthError error) {
case kDBAuthSuccess:
  AccountAuthData auth_data;
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
    void dbauth_intro(AuthCard) = 2;
  }
  = 1;
}
= 0x8aa87aa9;

struct IntroAuthResult {
  ShardCard shards<>;
};

program MempoolAuth {
  version MempoolAuth1 {
    IntroAuthResult mempoolauth_intro_auth(AuthCard) = 0;
  }
  = 1;
} = 0x8aa87aaa;

} // namespace hogd
