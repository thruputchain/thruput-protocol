namespace hogd {

program ExecutorCoord
{
  version ExecutorCoord1
  {

    void executorcoord_null(void) = 0;

    ExpectedProposalData executorcoord_propose_transaction(BlockID,
                                                           SignedTransaction) =
        10;
    RPCError executorcoord_validate_transaction(BlockID, ProposedTransaction) =
        20;

    // Executor can be in one of three states: None, Proposing, Validating
    // open_xyz_block() methods set the executor state, or return an error
    // if executor has already opened a block.
    // finish_block() blocks until all running executor threads are finished,
    // and stops the executor from accepting new transactions.
    RPCError executorcoord_open_proposal_block(BlockID) = 30;
    RPCError executorcoord_open_validation_block(BlockID) = 40;
    void executorcoord_finish_block(BlockID) = 50;

    // Coord should call this to shutdown the executor.
    // Shutdown will not occur until all pending transactions complete.
    // No new transactions or blocks can be opened after shutdown.
    void executorcoord_shutdown(void) = 60;
  }
  = 1;
}
= 0x7ee79999;

} // namespace hogd
