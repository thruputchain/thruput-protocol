// clang-format off

%#include "network.hh"
%#include "types.hh"
%#include "view.hh"

namespace hogd
{
// clang-format on

/// Successful view payload returned by ViewGateway1::viewgateway_view.
///
/// The height is the committed snapshot height used for the full view
/// execution, not a post-execution tip sample. gas_consumed is
/// TransactionViewResult::gas_consumed for that execution.
struct ViewGatewayPayload {
  BlockHeight height;
  InvocationFrameOutput output;
  GasAmount gas_consumed;
  TxEmittedEvent events<>;
};

enum ViewGatewayOutcome {
  ViewGatewayOk = 0,

  // Raw view attempts returned Abandoned until the bounded service retry
  // budget was exhausted. Callers may retry the public view request later.
  ViewGatewayAbandoned = 1,

  // Server-side invariant failure or unavailable execution dependency.
  ViewGatewayInternalError = 2,

  // The request was rejected before any frame output existed: forwarded
  // tokens without a parent address or deeper than the network allows, an
  // invocation the executor would not admit, or a root frame that failed on a
  // syscall error before it returned, aborted, or faulted. Deterministic for
  // the same request against the same state, so retrying does not help. The
  // error_code arm carries the SyscallErrorCode the executor reported.
  ViewGatewayInvalidInput = 3
};

union ViewGatewayResult switch (ViewGatewayOutcome outcome)
{
case ViewGatewayOk:
  ViewGatewayPayload payload;
case ViewGatewayAbandoned:
  void;
case ViewGatewayInternalError:
  void;
case ViewGatewayInvalidInput:
  SyscallErrorCode error_code;
default:
  void;
};

enum ViewGatewayIntroOutcome {
  ViewGatewayIntroSuccess = 0,
  ViewGatewayIntroMismatchedProtocol = 1
};

const kMaxViewBatchCalls = 16; // #[rust(const=u32)]
const kMaxViewBatchCalldataBytes = 65536; // #[rust(const=u32)]
const kMaxViewBatchGas = 160000000; // #[rust(const=u64)]
const kMaxViewBatchResponseBytes = 1048576; // #[rust(const=u32)]
const kMaxViewBatchBudgetMillis = 30000; // #[rust(const=u32)]

// Independent simulations against one committed snapshot. Calls do not see
// each other's simulated writes. Gas and calldata limits apply to the sum.
struct ViewGatewayBatchQuery {
  TransactionViewQuery calls<kMaxViewBatchCalls>;
  BlockHeight *min_height;
  // Remaining work budget from receipt, including scheduling and retries.
  // Must be in 1..=kMaxViewBatchBudgetMillis. Running calls remain gas-bounded.
  unsigned int budget_millis;
};

struct ViewGatewayBatchPayload {
  BlockHeight height;
  TransactionViewResult results<kMaxViewBatchCalls>;
};

struct ViewGatewayHeightUnavailable {
  BlockHeight requested;
  BlockHeight observed;
};

enum ViewGatewayBatchOutcome {
  ViewGatewayBatchOk = 0,
  ViewGatewayBatchInvalidRequest = 1,
  ViewGatewayBatchHeightUnavailable = 2,
  ViewGatewayBatchAbandoned = 3,
  ViewGatewayBatchDeadlineExceeded = 4,
  ViewGatewayBatchResponseTooLarge = 5,
  ViewGatewayBatchInternalError = 6
};

// Success contains exactly one ordered result per input call, all from height.
// Contract aborts and faults are per-call results. Other failures discard the
// whole attempt; abandoned batches retry as a group, never one call at a time.
union ViewGatewayBatchResult switch (ViewGatewayBatchOutcome outcome)
{
case ViewGatewayBatchOk:
  ViewGatewayBatchPayload payload;
case ViewGatewayBatchHeightUnavailable:
  ViewGatewayHeightUnavailable height_unavailable;
default:
  void;
};

// Executor-owned read-only invocation service used by public RPC gateways.
program ViewGateway
{
  version ViewGateway1
  {
    ViewGatewayIntroOutcome viewgateway_intro(ProtocolCommit) = 0;
    ViewGatewayResult viewgateway_view(TransactionViewQuery) = 1;
    ViewGatewayBatchResult viewgateway_view_batch(ViewGatewayBatchQuery) = 2;
  } = 1;
}
= 0x56475759;

} // namespace hogd
