// clang-format off
%#include "types.hh"

namespace hogd {
// clang-format on

typedef string ProgramArg<>;
struct ServerConfig {
  string program_name<>;
  ProgramArg program_args<>;
};

typedef string HogdGitHash<>;

enum CIServerErrorCode {
  kCIServerErrorCodeOK = 0,
  kCIServerErrorCodeAlreadyRunning = 1,
  kCIServerErrorCodeInternal = 2,
  kCIServerErrorCodeVersionMismatch = 3
};

union CIProcStatus switch (CIServerErrorCode error_code) {
case kCIServerErrorCodeOK:
  int exit_code;
default:
  // kCIServerErrorCodeAlreadyRunning indicates the process is still running
  // all other errors indicate CI failures
  void;
};

program CIServer
{
  version CIServer1
  {
    CIServerErrorCode ciserver_start(HogdGitHash, ServerConfig) = 0;
    void ciserver_stop(HogdGitHash) = 1;
    void ciserver_shutdown(HogdGitHash) = 2;
    // returns the status of the most recent process
    CIProcStatus ciserver_query_proc_status(HogdGitHash) = 3;
  }
  = 1;
}
= 0x11117668;

} // namespace hogd
