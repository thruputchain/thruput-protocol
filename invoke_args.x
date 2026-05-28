%#include "invoke_flag.hh"
%#include "types.hh"

namespace hogd {

struct CopyableInvokeInputs {
    unsigned hyper entrypoint_id;
    GasAmount gas_limit;
    InvokeFlagSet flags;
};

struct CopyableInvokeOutputs {
    RuntimeMemoryLength return_buffer_len;
    RuntimeMemoryLength returned_auth_token_len;
};

} // namespace hogd
