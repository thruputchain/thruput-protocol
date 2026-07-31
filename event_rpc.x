%#include "consensus.hh"
%#include "db_conflict.hh"
%#include "event.hh"
%#include "proposal.hh"
%#include "rpc_types.hh"
%#include "transaction.hh"

namespace hogd {

program EventExecutor
{
  version EventExecutor1
  {
    void eventexecutor_null(void) = 0;

    // Called when executor opens a block - increments executor handle count
    RPCError eventexecutor_open_block(BlockID) = 31;

    // Called when executor closes its handle to a block - decrements count
    RPCError eventexecutor_close_block(BlockID) = 32;

    // Best-effort report that a transaction failed nondeterministically
    // during 2-phase commit and was excluded from the proposal. The event
    // server relays this immediately to every registered indexer; it touches
    // no per-block state (the tx will never commit, so it has no place in
    // the commit pipeline). The executor sends fire-and-forget and ignores
    // the result.
    RPCError eventexecutor_report_tx_failure(SignedTransactionHash,
                                             TxFailureDiagnostic) = 33;

    // A transaction should not call this more than once
    // We don't technically need the transaction ID here;
    // however, this will help later with tracing RPC calls through the system,
    // and helps in testing.
    //
    // The ProposedTransaction carries the full transaction body (signed_tx +
    // nondeterministic data) so the event server can forward bodies to the
    // indexer alongside the event log.  In proposal mode the executor assembles
    // it from the SignedTransaction it executed plus the nondeterministic data
    // it produced; in validation mode it is the ProposedTransaction it was given.
    RPCError eventexecutor_emit_event(BlockID, TransactionID, TxEventLog,
                                      ProposedTransaction) = 30;
  } = 1;
} = 0x8aa81224;

union EventBlockResult switch (RPCError error) {
case kRPCNone:
  SHA256Hash root_hash;
default:
  void;
};

program EventSched
{
  version EventSched1
  {
    void eventsched_null(void) = 0;

    RPCError eventsched_open_block(BlockID) = 10;
    EventBlockResult eventsched_close_block(BlockID, BlockHeight,
                                            ProposalTxs) = 30;
    RPCError eventsched_commit_block(BlockID, ConsensusValue) = 31;
    // Called only after both HogDB and event durable commits succeed. This
    // releases the committed record for indexer delivery.
    RPCError eventsched_confirm_committed_block(ConsensusValue) = 32;
    RPCError eventsched_abandon_block(BlockID) = 40;
  } = 1;
} = 0x8aa81226;

} // namespace hogd
