%#include "syscall.hh"
%#include "storage_item.hh"
%#include "transaction.hh"
%#include "address_auth.hh"
%#include "auth_claim.hh"
%#include "event.hh"

namespace hogd
{

%struct InvocationFrameTrace;

// === Syscall Trace Unions and Structs ===

union SyscallSHA256Output switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    SHA256Hash hash;
  } success;
default:
  void;
};

struct SyscallSHA256Trace {
  opaque input<>;
  SyscallSHA256Output output;
};

union SyscallGetMsgSenderOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress sender;
  } success;
default:
  void;
};

struct SyscallGetMsgSenderTrace {
  SyscallGetMsgSenderOutput output;
};

union SyscallGetCalldataLenOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int len;
  } success;
default:
  void;
};

struct SyscallGetCalldataLenTrace {
  SyscallGetCalldataLenOutput output;
};

union SyscallGetCalldataOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque calldata<>;
  } success;
default:
  void;
};

struct SyscallGetCalldataTrace {
  SyscallGetCalldataOutput output;
};

union SyscallConsoleLogOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallConsoleLogTrace {
  opaque buffer<>;
  SyscallConsoleLogOutput output;
};

union SyscallInvokeOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    InvocationFrameTrace *child_trace;
  } success;
default:
  void;
};

struct SyscallInvokeTrace {
  ContractAddress address;
  unsigned hyper entrypoint_id;
  GasAmount gas_limit;
  opaque calldata<>;
  InvokeFlagSet flags;
  SyscallInvokeOutput output;
};

union SyscallReturnOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallReturnTrace {
  opaque buffer<>;
  bool revert_frame;
  SyscallReturnOutput output;
};

union SyscallGetReturnedBufferOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque buffer<>;
  } success;
default:
  void;
};

struct SyscallGetReturnedBufferTrace {
  SyscallGetReturnedBufferOutput output;
};

union SyscallExitOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallExitTrace {
  SyscallExitOutput output;
};

union SyscallGetDeployAddressOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress to_be_deployed;
  } success;
default:
  void;
};

struct SyscallGetDeployAddressTrace {
  SHA256Hash nonce;
  SHA256Hash contract_hash;
  SyscallGetDeployAddressOutput output;
};

union SyscallDeployContractOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress deployed_address;
  } success;
default:
  void;
};

struct SyscallDeployContractTrace {
  SHA256Hash nonce;
  SHA256Hash contract_hash;
  SyscallDeployContractOutput output;
};

union SyscallGetSourceTransactionHashOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    SHA256Hash source_tx_hash;
  } success;
default:
  void;
};

struct SyscallGetSourceTransactionHashTrace {
  SyscallGetSourceTransactionHashOutput output;
};

union SyscallVerifySignatureOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallVerifySignatureTrace {
  int scheme;
  opaque signature<>;
  opaque public_key<>;
  opaque message<>;
  SyscallVerifySignatureOutput output;
};

union SyscallBytestringGetLenOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int length;
  } success;
default:
  void;
};

struct SyscallBytestringGetLenTrace {
  StorageKeyContractData key;
  SyscallBytestringGetLenOutput output;
};

union SyscallBytestringGetOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque bytestring<>;
  } success;
default:
  void;
};

struct SyscallBytestringGetTrace {
  StorageKeyContractData key;
  SyscallBytestringGetOutput output;
};

union SyscallBytestringSetOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallBytestringSetTrace {
  StorageKeyContractData key;
  opaque bytestring<>;
  StorageDeltaFlagSet flags;
  SyscallBytestringSetOutput output;
};

union SyscallNonnegativeIntGetOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    int128_xdr *current_set;
    int128_xdr current_add;
  } success;
default:
  void;
};

struct SyscallNonnegativeIntGetTrace {
  StorageKeyContractData key;
  bool force_load;
  SyscallNonnegativeIntGetOutput output;
};

union SyscallNonnegativeIntSetAddOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallNonnegativeIntSetAddTrace {
  StorageKeyContractData key;
  int128_xdr *set_value;
  int128_xdr add_value;
  StorageDeltaFlagSet flags;
  SyscallNonnegativeIntSetAddOutput output;
};

union SyscallDeleteObjectOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallDeleteObjectTrace {
  StorageKeyContractData key;
  int flags;
  SyscallDeleteObjectOutput output;
};

union SyscallGetCurrentAddressOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    ContractAddress address;
  } success;
default:
  void;
};

struct SyscallGetCurrentAddressTrace {
  SyscallGetCurrentAddressOutput output;
};

union SyscallRetrocausalQueueInsertOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallRetrocausalQueueInsertTrace {
  StorageKeyContractData key;
  opaque queue_entry<>;
  SyscallRetrocausalQueueInsertOutput output;
};

union SyscallRetrocausalQueueConsumeOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    opaque queue_entry<>;
  } success;
default:
  void;
};

struct SyscallRetrocausalQueueConsumeTrace {
  StorageKeyContractData key;
  bool peek;
  SyscallRetrocausalQueueConsumeOutput output;
};

union SyscallGetTransactionStatisticsOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned hyper result;
  } success;
default:
  void;
};

struct SyscallGetTransactionStatisticsTrace {
  int statistic;
  SyscallGetTransactionStatisticsOutput output;
};

union SyscallChangePublicKeyRegistrationOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallChangePublicKeyRegistrationTrace {
  unsigned int key_index;
  int *key_scheme;
  opaque key_bytes<>;
  unsigned int *key_weight;
  SyscallChangePublicKeyRegistrationOutput output;
};

union SyscallLogEventOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallLogEventTrace {
  opaque data<>;
  Topic topics<3>;
  SyscallLogEventOutput output;
};

union SyscallGetAuthClaimCountOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    unsigned int count;
  } success;
default:
  void;
};

struct SyscallGetAuthClaimCountTrace {
  SyscallGetAuthClaimCountOutput output;
};

union SyscallGetAuthClaimOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    AuthClaim auth_claim;
  } success;
default:
  void;
};

struct SyscallGetAuthClaimTrace {
  unsigned int index;
  SyscallGetAuthClaimOutput output;
};

union SyscallSHA256UpdateOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallSHA256UpdateTrace {
  unsigned int index;
  opaque buffer<>;
  bool reset;
  SyscallSHA256UpdateOutput output;
};

union SyscallSHA256FinalizeOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    SHA256Hash hash;
  } success;
default:
  void;
};

struct SyscallSHA256FinalizeTrace {
  unsigned int index;
  SyscallSHA256FinalizeOutput output;
};

union SyscallWriteAddressNonceConfigOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallWriteAddressNonceConfigTrace {
  NonceConfig nonce_config;
  SyscallWriteAddressNonceConfigOutput output;
};

union SyscallWriteAddressGasPermissionConfigsOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  void;
default:
  void;
};

struct SyscallWriteAddressGasPermissionConfigsTrace {
  GasPermissionConfig permissions<5>;
  SyscallWriteAddressGasPermissionConfigsOutput output;
};

union SyscallGetBlockHeightOutput switch (SyscallErrorCode error)
{
case kSyscallErrorCodeNone:
  struct {
    BlockHeight result;
  } success;
default:
  void;
};

struct SyscallGetBlockHeightTrace {
  SyscallGetBlockHeightOutput output;
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
