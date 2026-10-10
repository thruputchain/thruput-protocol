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

// Sequential calls in one private execution context over a committed snapshot.
// Successful writes are visible to later calls, but never persist. The caller
// is the parent of every supplied invocation; nested calls use normal rules.
// This does not validate a transaction envelope or prove authorization.
// The trusted gateway applies operator request limits before dispatch.
struct ViewGatewayBatchQuery {
  ContractAddress caller;
  Invocation calls<>;
  // Freshness floor only: reject an older snapshot without waiting or
  // requesting a refresh. Snapshot maintenance is shared across requests.
  BlockHeight *min_height;
  // Remaining work budget from receipt, including scheduling and retries.
  // Must be positive. Running calls remain gas-bounded.
  unsigned int budget_millis;
  // Maximum XDR-encoded ViewGatewayBatchResult, including events.
  // Must be positive; enforced while constructing the result.
  unsigned int max_response_bytes;
};

struct ViewBatchReturnedCall {
  ReturnBuffer return_buffer;
  GasAmount gas_consumed;
  // Only this call's events, including successful nested calls, in order.
  TxEmittedEvent events<>;
};

struct ViewBatchAbortedCall {
  ReturnBuffer abort_buffer;
  GasAmount gas_consumed;
};

enum ViewBatchCallStatus {
  ViewBatchCallReturned = 0,
  ViewBatchCallAborted = 1,
  ViewBatchCallFaulted = 2,
  ViewBatchCallRejected = 3,
  ViewBatchCallNotExecuted = 4
};

// Reverted frames have no surviving events. Rejection precedes frame execution;
// it has an error code rather than fabricated output or gas. NotExecuted is
// reserved for the suffix after the first failed call.
union ViewBatchCallResult switch (ViewBatchCallStatus status)
{
case ViewBatchCallReturned:
  ViewBatchReturnedCall returned;
case ViewBatchCallAborted:
  ViewBatchAbortedCall aborted;
case ViewBatchCallFaulted:
  GasAmount gas_consumed;
case ViewBatchCallRejected:
  SyscallErrorCode error_code;
case ViewBatchCallNotExecuted:
  void;
};

enum ViewBatchExecutionStatus {
  ViewBatchExecutionSucceeded = 0,
  ViewBatchExecutionFailed = 1
};

union ViewBatchExecutionOutcome switch (ViewBatchExecutionStatus status)
{
case ViewBatchExecutionSucceeded:
  void;
case ViewBatchExecutionFailed:
  unsigned int failed_call_index;
};

struct ViewGatewayBatchPayload {
  // Starting committed height H; all calls share the view execution context.
  BlockHeight height;
  ViewBatchExecutionOutcome execution;
  // Sum of call gas, excluding discarded attempts. Must not overflow.
  GasAmount gas_consumed;
  ViewBatchCallResult results<>;
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

// Ok means simulation completed, not that every call succeeded. The payload
// contains exactly one result per input. Success requires all Returned; failure
// requires a Returned prefix, one Aborted/Faulted/Rejected at failed_call_index,
// then a NotExecuted suffix. Earlier returns/events are diagnostics on failure,
// not successful whole-sequence effects. No writes persist in either case.
// Infrastructure failures discard the whole attempt; abandoned batches retry
// from call zero with fresh private state, never one call at a time.
// This replaces the independent-call wire contract. Peers must pass the exact
// protocol-identity handshake; never reinterpret an older batch response.
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
