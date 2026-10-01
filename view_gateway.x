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

// Executor-owned read-only invocation service used by public RPC gateways.
program ViewGateway
{
  version ViewGateway1
  {
    ViewGatewayIntroOutcome viewgateway_intro(ProtocolCommit) = 0;
    ViewGatewayResult viewgateway_view(TransactionViewQuery) = 1;
  } = 1;
}
= 0x56475759;

} // namespace hogd
