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
    // This version should be called when validating a nomination, in which if even one
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
  kDBAuthInternal = 3
};

union DBAuthResult switch (DBAuthError error) {
case kDBAuthSuccess:
  AddressAuthData auth_data;
default:
  void;
};

enum DBAuthIntroOutcome {
  kSuccess = 0,
  kFailure = 1
};

union DBAuthIntroResult switch (DBAuthIntroOutcome outcome) {
case kSuccess:
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

union IntroAuthResult switch (IntroAuthOutcome outcome)
{
case kSuccess:
  ShardCard shards<>;
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
