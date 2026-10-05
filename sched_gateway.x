// clang-format off

%#include "network.hh"
%#include "parallel.hh"
%#include "rpc_types.hh"
%#include "sched_coord.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd
{
// clang-format on

enum SchedGatewayIntroOutcome {
  SchedGatewayIntroSuccess = 0,
  SchedGatewayIntroMismatchedProtocol = 1
};

// The admission result for one exact SignedTransaction encoding in one
// gateway submission request. A rejection must not be cached or reused by
// TransactionHash: signatures are not part of that hash.
//
// A successful RPC returns exactly one outcome per decoded transaction, in
// submission order. A malformed request or cardinality mismatch is an RPC or
// protocol error; consumers must not infer partial acceptance from it.
enum SchedGatewaySubmitOutcome {
  // The transaction was admitted to the mempool, or the same transaction body
  // was already pending. This does not mean it was nominated or committed.
  SchedGatewaySubmitAdmitted = 0,
  // This request definitely did not admit the transaction because
  // authentication failed against the state observed for this request.
  SchedGatewaySubmitAuthenticationRejected = 1,
  // This request definitely did not admit the transaction because of a
  // transient admission condition; retrying it unchanged may succeed.
  SchedGatewaySubmitRetryable = 2,
  // This request definitely did not admit the transaction because an internal
  // dependency failed. An RPC failure instead makes admission indeterminate.
  SchedGatewaySubmitInternalError = 3
};

typedef SchedGatewaySubmitOutcome SchedGatewaySubmitOutcomeBatch<>;

// Number of transactions currently pending in the mempool.
typedef hyper PendingTxCount;

// API exposed from the Scheduler for the public RPC Gateway.
program SchedGateway
{
  version SchedGateway1
  {
    SchedGatewayIntroOutcome schedgateway_intro(ProtocolCommit) = 0;

    // Submit wallet-originated transactions and return the request-scoped,
    // exact-cardinality admission outcomes described above. A malformed batch
    // fails at the RPC level because its transactions cannot be identified
    // reliably. Admission does not imply commitment; clients learn about commit
    // via getTransactionStatus / getTransactionReceipt polling.
    SchedGatewaySubmitOutcomeBatch schedgateway_submit_tx_batch(
      ParallelSignedTransactionBatch) = 1;

    // Current committed tip.  Returns kRPCNotFound when the node
    // has no committed block yet (pre-genesis bootstrap).
    ExpectedDBTip schedgateway_get_tip(void) = 2;

    // Lookup in-flight (not-yet-committed) transactions by hash.
    // Returns one OptSignedTransaction per input hash (same order).
    OptSignedTransactionBatch schedgateway_lookup_tx(TransactionHashBatch) = 3;

    // Number of transactions currently pending in the mempool.
    PendingTxCount schedgateway_pending_tx_count(void) = 4;

    // Returns one pending or recent outcome per input hash (same order).
    SchedulerTransactionOutcomeBatch schedgateway_lookup_transaction_outcomes(TransactionHashBatch) = 5;
  } = 1;
}
= 0x7ee7aaaa;

} // namespace hogd
