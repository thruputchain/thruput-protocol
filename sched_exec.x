// clang-format off
%#include "rpc_types.hh"
%#include "types.hh"
namespace hogd {
// clang-format on

// Uniquely describes an executor instance.
struct ExecCard {
  Protocol protocol;
  UPID upid;
  ServerAddress address;
};

struct IntroExecResult {
  // A unique 16-bit identifier assigned to the executor by the system.
  unsigned int exec_id;

  // The database shards.
  ShardCard shards<>;
};

program SchedExec
{
  version SchedExec1
  {
    // [schedexec_intro_exec] is called by an executor to introduce itself to
    // the system.
    void schedexec_intro_exec(ExecCard) = 1;
  }
  = 1;
}
= 0x7ee79997;

} // namespace hogd
