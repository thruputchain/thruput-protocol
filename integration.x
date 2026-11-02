namespace hogd {
// clang-format on

/// kCoordinatorMaxBytesTxsMessage is the maximum size of a dissemination
/// message containing transactions. The transaction batches inside these
/// messages will be submitted to the mempool as vetted txs.
/// Thus the mempool-to-coordinator RPC must have a slightly higher
/// maximum message size to accommodate for RPC framing.
const kCoordinatorMaxBytesTxsMessage = 2'000'000'000; // 2GB
const kMempoolCoordinatorRpcMaxBytes = 2'000'010'000; // 2GB + 10KB

/// kCoordinatorMaxBytesCVMessage is the maximum size of a dissemination
/// message containing consensus values.
const kCoordinatorMaxBytesCVMessage = 70'000'000; // 70MB

/// kCoordinatorMaxBytesSCPEnvelopeMessage is the maximum size of a dissemination
/// message containing an SCP envelope. These messages are passed on to SCPD verbatim.
/// Thus the SCPD controller RPC (used by the coordinator) must have a slightly higher
/// maximum message size to accommodate for RPC framing.
const kCoordinatorMaxBytesSCPEnvelopeMessage = 5'000'000; // 5MB

/// kCoordinatorMaxBytesSCPQuorumSet is the maximum acceptable encoded quorum set size,
/// enforced at the coordinator.
const kCoordinatorMaxBytesSCPQuorumSet = 1'000'000; // 1MB

/// kMaxBytesSignedTransaction is the maximum encoded size of a signed transaction;
/// the auth server rejects larger ones.
/// This bound is also used by the coordinator to calculate how many unvetted transactions it can buffer
/// before submitting them to the mempool without violating kMempoolCoordinatorRpcMaxBytes.
const kMaxBytesSignedTransaction = 2'000'000; // 2MB

/// kRPCFrameMaxBytes is an over-estimate of the maximum RPC frame size, used by the coordinator
/// to make sure it does not overflow the mempool's max RPC message size.
const kRPCFrameMaxBytes = 10'000; // 10KB

} // namespace hogd
