%#include "syscall.hh"
%#include "storage_item.hh"
%#include "transaction.hh"

namespace hogd
{

union SyscallSHA256Trace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque input<>;
    SHA256Hash output;
  } success;
default:
  void;
};

union SyscallTraceBody switch (SyscallNo syscall_number)
{
case kSHA256:
  SyscallSHA256Trace sha256;
default:
  void;
};

union HostFunctionStatusXdr switch (HostFnErrorCode error)
{
case kHostNoneOrRecoverable:
  SyscallErrorCode syscall_return_code;
default:
  void;
};

struct SyscallTrace {
  GasAmount gas_remaining_at_start;
  GasAmount gas_remaining_at_end;

  SyscallTraceBody body;

  HostFunctionStatusXdr status;
};

enum InvocationFrameStatusCode {
  kFrameReturn = 0,
  kFrameFault = 1,
  kFrameAbort = 2,
};

union InvocationFrameStatus switch (InvocationFrameStatusCode status_code)
{
case kFrameReturn:
case kFrameAbort:
  opaque buffer<>;
case kFrameFault:
  void;
};

struct InvocationFrameTrace {
  Invocation invocation;

  /// The ordered list of system calls made by this frame.
  SyscallTrace system_calls<>;

  /// The set of storage writes made by this frame,
  /// when the frame terminates.
  /// Note that this field may be nonempty even if the frame Faults or Aborts;
  /// In such a case, these writes will not be applied to the parent frame,
  /// but are still reported in the trace for testing purposes.
  FlaggedStorageDelta storage_writes<>;

  /// Status of the frame when it terminates.
  InvocationFrameStatus status;
};

} // namespace hogd
