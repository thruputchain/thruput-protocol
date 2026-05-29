%#include "invoke_flag.hh"
%#include "types.hh"
%#include "transaction.hh"

namespace hogd {

struct CopyableInvokeInputs {
  unsigned hyper entrypoint_id;
  GasAmount gas_limit;
  InvokeFlagSet flags;
};

struct CopyableInvokeOutputs {
  RuntimeMemoryLength return_buffer_len;
  RuntimeMemoryLength returned_auth_token_len;
  // The outcome of the child frame. Only meaningful when the Invoke syscall
  // returns kSyscallErrorCodeNone (i.e. a child frame actually ran):
  //   Return -> child returned normally; return_buffer_len bytes available
  //   Abort  -> child manually reverted; abort buffer available
  //   Fault  -> child trapped / ran out of gas; no return buffer
  // Left untouched when the syscall returns a nonzero error code (the call
  // was rejected before any child frame ran, and is a complete no-op).
  InvocationFrameStatusCode frame_status;
};

} // namespace hogd
