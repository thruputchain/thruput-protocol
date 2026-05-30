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

// Number of transactions currently pending in the mempool.
typedef hyper PendingTxCount;

// API exposed from the Scheduler for the public RPC Gateway.
program SchedGateway
{
  version SchedGateway1
  {
    SchedGatewayIntroOutcome schedgateway_intro(Protocol) = 0;

    // Submit a batch of wallet-originated transactions to the
    // mempool.  Wallet clients learn about commit via
    // getTransactionStatus / getTransactionReceipt polling.
    void schedgateway_submit_tx_batch(ParallelSignedTransactionBatch) = 1;

    // Current committed tip.  Returns kRPCNotFound when the node
    // has no committed block yet (pre-genesis bootstrap).
    ExpectedDBTip schedgateway_get_tip(void) = 2;

    // Lookup in-flight (not-yet-committed) transactions by hash.
    // Returns one OptSignedTransaction per input hash (same order).
    OptSignedTransactionBatch schedgateway_lookup_tx(SignedTransactionHashBatch) = 3;

    // Number of transactions currently pending in the mempool.
    PendingTxCount schedgateway_pending_tx_count(void) = 4;
  } = 1;
}
= 0x7ee7aaaa;

} // namespace hogd
