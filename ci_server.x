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
  kCIServerErrorCodeVersionMismatch = 3,
};

program CIServer
{
  version CIServer1
  {
    CIServerErrorCode ciserver_start(HogdGitHash, ServerConfig) = 0;
    void ciserver_stop(HogdGitHash) = 1;
    void ciserver_shutdown(HogdGitHash) = 2;
  }
  = 1;
}
= 0x11117668;

} // namespace hogd
