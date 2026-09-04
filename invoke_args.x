%#include "invoke_flag.hh"
%#include "types.hh"
%#include "transaction.hh"

namespace hogd {

struct CopyableInvokeInputs {
  unsigned hyper entrypoint_id;
  GasAmount gas_limit;
  InvokeFlagSet flags;
  // Explicit tail padding so the aggregate has no implementation-defined
  // padding bytes. The RV32 syscall ABI decodes this struct by range-checking
  // and copying sizeof() bytes of guest memory, which is only a
  // host-layout-independent decode when every byte is a named field. Naming
  // the tail keeps std::has_unique_object_representations_v true, which the
  // by-reference syscall input path in hogd static_asserts. Ignored by the
  // host; not part of the invoke semantics (issue #3854).
  unsigned reserved;
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
