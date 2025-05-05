namespace hogd {

struct CatchupBlock {
  BlockHeight block_height;
  BlockHash block_hash;
  BlockHash prev_block_hash;
  ProposedTransaction proposed_transactions<>;
};

struct CatchupBlocksRequest {
  Timestamp timestamp;
  // We intentionally use only block height (and not block hashes) to enable the
  // requester to ask for blocks whose hashes are not known ahead of time. For
  // instance, the caller can request the block that is currently being
  // prepared.
  BlockHeight onto_block_height;
};

struct SignedCatchupBlocksRequest {
  ValidatorPublicInfo signer;
  Signature signature;
  CatchupBlocksRequest request;
};

struct CatchupBlocksResult {
  Timestamp timestamp;
  CatchupBlock blocks<>;
};

struct SignedCatchupBlocksResult {
  ValidatorPublicInfo signer;
  Signature signature;
  CatchupBlocksResult result;
};

// Catchup service enables validators that are lagging behind SCP to recover a
// small number of missed blocks.
program Catchup
{
  version Catchup1
  {

    void catchup_null(void) = 0;

    SignedCatchupBlocksResult catchup_blocks(SignedCatchupBlocksRequest) = 10;
  }
  = 1;
}
= 0x4321abcd;

} // namespace hogd
