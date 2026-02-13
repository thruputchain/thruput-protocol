%#include "syscall.hh"
%#include "storage_item.hh"
%#include "transaction.hh"
%#include "address_auth.hh"
%#include "auth_claim.hh"
%#include "event.hh"

namespace hogd
{

%struct InvocationFrameTrace;

// === Syscall Trace Unions ===
// Each follows the pattern: success case holds inputs+outputs, default is void.

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

union SyscallGetMsgSenderTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress sender;
  } success;
default:
  void;
};

union SyscallGetCalldataLenTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int len;
  } success;
default:
  void;
};

union SyscallGetCalldataTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque calldata<>;
  } success;
default:
  void;
};

union SyscallConsoleLogTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque buffer<>;
  } success;
default:
  void;
};

union SyscallInvokeTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress address;
    unsigned hyper entrypoint_id;
    GasAmount gas_limit;
    opaque calldata<>;
    InvokeFlagSet flags;
    unsigned int return_buffer_len;
    InvocationFrameTrace *child_trace;
  } success;
default:
  void;
};

union SyscallReturnTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque buffer<>;
    bool revert_frame;
  } success;
default:
  void;
};

union SyscallGetReturnedBufferTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque buffer<>;
  } success;
default:
  void;
};

// kExit has no data for any case
union SyscallExitTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

union SyscallGetDeployAddressTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    SHA256Hash nonce;
    SHA256Hash contract_hash;
    ContractAddress to_be_deployed;
  } success;
default:
  void;
};

union SyscallDeployContractTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    SHA256Hash nonce;
    SHA256Hash contract_hash;
    ContractAddress deployed_address;
  } success;
default:
  void;
};

union SyscallGetSourceTransactionHashTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    SHA256Hash source_tx_hash;
  } success;
default:
  void;
};

union SyscallVerifySignatureTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    int scheme;
    opaque signature<>;
    opaque public_key<>;
    opaque message<>;
  } success;
default:
  void;
};

union SyscallBytestringGetLenTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    unsigned int length;
  } success;
default:
  void;
};

union SyscallBytestringGetTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    opaque bytestring<>;
  } success;
default:
  void;
};

union SyscallBytestringSetTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    opaque bytestring<>;
    StorageDeltaFlagSet flags;
  } success;
default:
  void;
};

union SyscallNonnegativeIntGetTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    bool force_load;
    int128_xdr *current_set;
    int128_xdr current_add;
  } success;
default:
  void;
};

union SyscallNonnegativeIntSetAddTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    int128_xdr *set_value;
    int128_xdr add_value;
    StorageDeltaFlagSet flags;
  } success;
default:
  void;
};

union SyscallDeleteObjectTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    int flags;
  } success;
default:
  void;
};

union SyscallGetCurrentAddressTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress address;
  } success;
default:
  void;
};

union SyscallRetrocausalQueueInsertTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    opaque queue_entry<>;
  } success;
default:
  void;
};

union SyscallRetrocausalQueueConsumeTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    StorageKeyContractData key;
    bool peek;
    opaque queue_entry<>;
  } success;
default:
  void;
};

union SyscallGetTransactionStatisticsTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    int statistic;
    unsigned hyper result;
  } success;
default:
  void;
};

union SyscallChangePublicKeyRegistrationTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int key_index;
    int *key_scheme;
    opaque key_bytes<>;
    unsigned int *key_weight;
  } success;
default:
  void;
};

union SyscallLogEventTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque data<>;
    Topic topics<3>;
  } success;
default:
  void;
};

union SyscallGetAuthClaimCountTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int count;
  } success;
default:
  void;
};

union SyscallGetAuthClaimTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int index;
    AuthClaim auth_claim;
  } success;
default:
  void;
};

union SyscallSHA256UpdateTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int index;
    opaque buffer<>;
    bool reset;
  } success;
default:
  void;
};

union SyscallSHA256FinalizeTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int index;
    SHA256Hash output;
  } success;
default:
  void;
};

union SyscallWriteAddressNonceConfigTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    NonceConfig nonce_config;
  } success;
default:
  void;
};

union SyscallWriteAddressGasPermissionConfigsTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    GasPermissionConfig permissions<5>;
  } success;
default:
  void;
};

union SyscallGetBlockHeightTrace switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    BlockHeight result;
  } success;
default:
  void;
};

// === Main Trace Body ===

union SyscallTraceBody switch (SyscallNo syscall_number)
{
case kSHA256:
  SyscallSHA256Trace sha256;
case kGetMsgSender:
  SyscallGetMsgSenderTrace get_msg_sender;
case kGetCalldataLen:
  SyscallGetCalldataLenTrace get_calldata_len;
case kGetCalldata:
  SyscallGetCalldataTrace get_calldata;
case kConsoleLog:
  SyscallConsoleLogTrace console_log;
case kInvoke:
  SyscallInvokeTrace invoke;
case kReturn:
  SyscallReturnTrace return_trace;
case kGetReturnedBuffer:
  SyscallGetReturnedBufferTrace get_returned_buffer;
case kExit:
  SyscallExitTrace exit_trace;
case kGetDeployAddress:
  SyscallGetDeployAddressTrace get_deploy_address;
case kDeployContract:
  SyscallDeployContractTrace deploy_contract;
case kGetSourceTransactionHash:
  SyscallGetSourceTransactionHashTrace get_source_transaction_hash;
case kVerifySignature:
  SyscallVerifySignatureTrace verify_signature;
case kBytestringGetLen:
  SyscallBytestringGetLenTrace bytestring_get_len;
case kBytestringGet:
  SyscallBytestringGetTrace bytestring_get;
case kBytestringSet:
  SyscallBytestringSetTrace bytestring_set;
case kNonnegativeIntGet:
  SyscallNonnegativeIntGetTrace nonnegative_int_get;
case kNonnegativeIntSetAdd:
  SyscallNonnegativeIntSetAddTrace nonnegative_int_set_add;
case kDeleteObject:
  SyscallDeleteObjectTrace delete_object;
case kGetCurrentAddress:
  SyscallGetCurrentAddressTrace get_current_address;
case kRetrocausalQueueInsert:
  SyscallRetrocausalQueueInsertTrace retrocausal_queue_insert;
case kRetrocausalQueueConsume:
  SyscallRetrocausalQueueConsumeTrace retrocausal_queue_consume;
case kGetTransactionStatistics:
  SyscallGetTransactionStatisticsTrace get_transaction_statistics;
case kChangePublicKeyRegistration:
  SyscallChangePublicKeyRegistrationTrace change_public_key_registration;
case kLogEvent:
  SyscallLogEventTrace log_event;
case kGetAuthClaimCount:
  SyscallGetAuthClaimCountTrace get_auth_claim_count;
case kGetAuthClaim:
  SyscallGetAuthClaimTrace get_auth_claim;
case kSHA256Update:
  SyscallSHA256UpdateTrace sha256_update;
case kSHA256Finalize:
  SyscallSHA256FinalizeTrace sha256_finalize;
case kWriteAddressNonceConfig:
  SyscallWriteAddressNonceConfigTrace write_address_nonce_config;
case kWriteAddressGasPermissionConfigs:
  SyscallWriteAddressGasPermissionConfigsTrace write_address_gas_permission_configs;
case kGetBlockHeight:
  SyscallGetBlockHeightTrace get_block_height;
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
  InvocationFrameOutput status;
};

} // namespace hogd
