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

struct SyscallSHA256Inputs {
  opaque input<>;
};

struct SyscallSHA256Outputs {
  SHA256Hash hash;
};

struct SyscallSHA256Trace {
  SyscallSHA256Inputs inputs;
  SyscallSHA256Outputs *outputs;
};

struct SyscallGetMsgSenderInputs {
  void;
};

struct SyscallGetMsgSenderOutputs {
  ContractAddress sender;
};

struct SyscallGetMsgSenderTrace {
  SyscallGetMsgSenderInputs inputs;
  SyscallGetMsgSenderOutputs *outputs;
};

struct SyscallGetCalldataLenInputs {
  void;
};

struct SyscallGetCalldataLenOutputs {
  unsigned int len;
  unsigned int auth_token_count;
};

struct SyscallGetCalldataLenTrace {
  SyscallGetCalldataLenInputs inputs;
  SyscallGetCalldataLenOutputs *outputs;
};

struct SyscallGetCalldataInputs {
  void;
};

struct SyscallGetCalldataOutputs {
  opaque calldata<>;
  unsigned int auth_tokens<>;
};

struct SyscallGetCalldataTrace {
  SyscallGetCalldataInputs inputs;
  SyscallGetCalldataOutputs *outputs;
};

struct SyscallConsoleLogInputs {
  opaque buffer<>;
};

struct SyscallConsoleLogOutputs {
  void;
};

struct SyscallConsoleLogTrace {
  SyscallConsoleLogInputs inputs;
  SyscallConsoleLogOutputs *outputs;
};

struct SyscallInvokeInputs {
  ContractAddress address;
  unsigned hyper entrypoint_id;
  GasAmount gas_limit;
  opaque calldata<>;
  InvokeFlagSet flags;
  opaque owned_auth_token_ids_list<>;
};

struct SyscallInvokeOutputs {
  InvocationFrameTrace *child_trace;
};

struct SyscallInvokeTrace {
  SyscallInvokeInputs inputs;
  SyscallInvokeOutputs *outputs;
};

struct SyscallReturnInputs {
  opaque buffer<>;
  bool revert_frame;
};

struct SyscallReturnOutputs {
  void;
};

struct SyscallReturnTrace {
  SyscallReturnInputs inputs;
  SyscallReturnOutputs *outputs;
};

struct SyscallGetReturnedBufferInputs {
  void;
};

struct SyscallGetReturnedBufferOutputs {
  ReturnBuffer buffer;
  opaque returned_auth_tokens<>;
};

struct SyscallGetReturnedBufferTrace {
  SyscallGetReturnedBufferInputs inputs;
  SyscallGetReturnedBufferOutputs *outputs;
};

struct SyscallExitInputs {
  void;
};

struct SyscallExitOutputs {
  void;
};

struct SyscallExitTrace {
  SyscallExitInputs inputs;
  SyscallExitOutputs *outputs;
};

struct SyscallGetDeployAddressInputs {
  ContractAddress *caller_address;
  SHA256Hash nonce;
  SHA256Hash contract_hash;
};

struct SyscallGetDeployAddressOutputs {
  ContractAddress to_be_deployed;
};

struct SyscallGetDeployAddressTrace {
  SyscallGetDeployAddressInputs inputs;
  SyscallGetDeployAddressOutputs *outputs;
};

struct SyscallDeployContractInputs {
  SHA256Hash nonce;
  SHA256Hash contract_hash;
};

struct SyscallDeployContractOutputs {
  ContractAddress deployed_address;
};

struct SyscallDeployContractTrace {
  SyscallDeployContractInputs inputs;
  SyscallDeployContractOutputs *outputs;
};

struct SyscallGetSourceTransactionHashInputs {
  void;
};

struct SyscallGetSourceTransactionHashOutputs {
  SHA256Hash source_tx_hash;
};

struct SyscallGetSourceTransactionHashTrace {
  SyscallGetSourceTransactionHashInputs inputs;
  SyscallGetSourceTransactionHashOutputs *outputs;
};

struct SyscallVerifySignatureInputs {
  int scheme;
  opaque signature<>;
  opaque public_key<>;
  opaque message<>;
};

struct SyscallVerifySignatureOutputs {
  void;
};

struct SyscallVerifySignatureTrace {
  SyscallVerifySignatureInputs inputs;
  SyscallVerifySignatureOutputs *outputs;
};

struct SyscallBytestringGetLenInputs {
  StorageKeyContractData key;
};

struct SyscallBytestringGetLenOutputs {
  unsigned int length;
};

struct SyscallBytestringGetLenTrace {
  SyscallBytestringGetLenInputs inputs;
  SyscallBytestringGetLenOutputs *outputs;
};

struct SyscallBytestringGetInputs {
  StorageKeyContractData key;
};

struct SyscallBytestringGetOutputs {
  Bytestring bytestring;
};

struct SyscallBytestringGetTrace {
  SyscallBytestringGetInputs inputs;
  SyscallBytestringGetOutputs *outputs;
};

struct SyscallBytestringSetInputs {
  StorageKeyContractData key;
  opaque bytestring<>;
  StorageDeltaFlagSet flags;
};

struct SyscallBytestringSetOutputs {
  void;
};

struct SyscallBytestringSetTrace {
  SyscallBytestringSetInputs inputs;
  SyscallBytestringSetOutputs *outputs;
};

struct SyscallNonnegativeIntGetInputs {
  StorageKeyContractData key;
  bool force_load;
};

struct SyscallNonnegativeIntGetOutputs {
  int128_xdr *current_set;
  int128_xdr current_add;
};

struct SyscallNonnegativeIntGetTrace {
  SyscallNonnegativeIntGetInputs inputs;
  SyscallNonnegativeIntGetOutputs *outputs;
};

struct SyscallNonnegativeIntSetAddInputs {
  StorageKeyContractData key;
  int128_xdr *set_value;
  int128_xdr add_value;
  StorageDeltaFlagSet flags;
};

struct SyscallNonnegativeIntSetAddOutputs {
  void;
};

struct SyscallNonnegativeIntSetAddTrace {
  SyscallNonnegativeIntSetAddInputs inputs;
  SyscallNonnegativeIntSetAddOutputs *outputs;
};

struct SyscallDeleteObjectInputs {
  StorageKeyContractData key;
  int flags;
};

struct SyscallDeleteObjectOutputs {
  void;
};

struct SyscallDeleteObjectTrace {
  SyscallDeleteObjectInputs inputs;
  SyscallDeleteObjectOutputs *outputs;
};

struct SyscallGetCurrentAddressInputs {
  void;
};

struct SyscallGetCurrentAddressOutputs {
  ContractAddress address;
};

struct SyscallGetCurrentAddressTrace {
  SyscallGetCurrentAddressInputs inputs;
  SyscallGetCurrentAddressOutputs *outputs;
};

struct SyscallRetrocausalQueueInsertInputs {
  StorageKeyContractData key;
  QueueEntry queue_entry;
};

struct SyscallRetrocausalQueueInsertOutputs {
  void;
};

struct SyscallRetrocausalQueueInsertTrace {
  SyscallRetrocausalQueueInsertInputs inputs;
  SyscallRetrocausalQueueInsertOutputs *outputs;
};

struct SyscallRetrocausalQueueConsumeInputs {
  StorageKeyContractData key;
  bool peek;
};

struct SyscallRetrocausalQueueConsumeOutputs {
  QueueEntry queue_entry;
};

struct SyscallRetrocausalQueueConsumeTrace {
  SyscallRetrocausalQueueConsumeInputs inputs;
  SyscallRetrocausalQueueConsumeOutputs *outputs;
};

struct SyscallGetTransactionStatisticsInputs {
  TransactionStatistic statistic;
};

struct SyscallGetTransactionStatisticsOutputs {
  unsigned hyper result;
};

struct SyscallGetTransactionStatisticsTrace {
  SyscallGetTransactionStatisticsInputs inputs;
  SyscallGetTransactionStatisticsOutputs *outputs;
};

struct SyscallChangePublicKeyRegistrationInputs {
  unsigned int key_index;
  int *key_scheme;
  opaque key_bytes<>;
  unsigned int *key_weight;
};

struct SyscallChangePublicKeyRegistrationOutputs {
  void;
};

struct SyscallChangePublicKeyRegistrationTrace {
  SyscallChangePublicKeyRegistrationInputs inputs;
  SyscallChangePublicKeyRegistrationOutputs *outputs;
};

struct SyscallLogEventInputs {
  Topic* topic0;
  Topic* topic1;
  Topic* topic2;
  opaque data<>;
};

struct SyscallLogEventOutputs {
  void;
};

struct SyscallLogEventTrace {
  SyscallLogEventInputs inputs;
  SyscallLogEventOutputs *outputs;
};

struct SyscallGetAuthClaimCountInputs {
  void;
};

struct SyscallGetAuthClaimCountOutputs {
  unsigned int count;
};

struct SyscallGetAuthClaimCountTrace {
  SyscallGetAuthClaimCountInputs inputs;
  SyscallGetAuthClaimCountOutputs *outputs;
};

struct SyscallGetAuthClaimInputs {
  unsigned int index;
};

struct SyscallGetAuthClaimOutputs {
  AuthClaim auth_claim;
};

struct SyscallGetAuthClaimTrace {
  SyscallGetAuthClaimInputs inputs;
  SyscallGetAuthClaimOutputs *outputs;
};

struct SyscallSHA256UpdateInputs {
  unsigned int index;
  opaque buffer<>;
  bool reset;
};

struct SyscallSHA256UpdateOutputs {
  void;
};

struct SyscallSHA256UpdateTrace {
  SyscallSHA256UpdateInputs inputs;
  SyscallSHA256UpdateOutputs *outputs;
};

struct SyscallSHA256FinalizeInputs {
  unsigned int index;
};

struct SyscallSHA256FinalizeOutputs {
  SHA256Hash hash;
};

struct SyscallSHA256FinalizeTrace {
  SyscallSHA256FinalizeInputs inputs;
  SyscallSHA256FinalizeOutputs *outputs;
};

struct SyscallWriteAddressNonceConfigInputs {
  NonceConfig nonce_config;
};

struct SyscallWriteAddressNonceConfigOutputs {
  void;
};

struct SyscallWriteAddressNonceConfigTrace {
  SyscallWriteAddressNonceConfigInputs inputs;
  SyscallWriteAddressNonceConfigOutputs *outputs;
};

struct SyscallWriteAddressGasPermissionConfigsInputs {
  GasPermissionConfig* permission0;
  GasPermissionConfig* permission1;
  GasPermissionConfig* permission2;
  GasPermissionConfig* permission3;
  GasPermissionConfig* permission4;
};

struct SyscallWriteAddressGasPermissionConfigsOutputs {
  void;
};

struct SyscallWriteAddressGasPermissionConfigsTrace {
  SyscallWriteAddressGasPermissionConfigsInputs inputs;
  SyscallWriteAddressGasPermissionConfigsOutputs *outputs;
};

struct SyscallGetBlockHeightInputs {
  void;
};

struct SyscallGetBlockHeightOutputs {
  BlockHeight result;
};

struct SyscallGetBlockHeightTrace {
  SyscallGetBlockHeightInputs inputs;
  SyscallGetBlockHeightOutputs *outputs;
};

struct SyscallRetrocausalQueuePeekLenInputs {
  StorageKeyContractData key;
};

struct SyscallRetrocausalQueuePeekLenOutputs {
  RuntimeMemoryLength len;
};

struct SyscallRetrocausalQueuePeekLenTrace {
  SyscallRetrocausalQueuePeekLenInputs inputs;
  SyscallRetrocausalQueuePeekLenOutputs *outputs;
};

struct SyscallMintAuthTokenInputs {
  BlockHeight expiry_height;
  opaque serialized_auth_token<>;
};

struct SyscallMintAuthTokenOutputs {
  unsigned int token_id;
};

struct SyscallMintAuthTokenTrace {
  SyscallMintAuthTokenInputs inputs;
  SyscallMintAuthTokenOutputs *outputs;
};

struct SyscallConsumeAuthTokenInputs {
  unsigned int token_id;
};

struct SyscallConsumeAuthTokenOutputs {
  AuthTokenPayload payload;
  unsigned int unwrapped_token_id_start;
  unsigned int unwrapped_token_id_count;
};

struct SyscallConsumeAuthTokenTrace {
  SyscallConsumeAuthTokenInputs inputs;
  SyscallConsumeAuthTokenOutputs *outputs;
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
case kRetrocausalQueuePeekLen:
  SyscallRetrocausalQueuePeekLenTrace retrocausal_queue_peek_len;
case kMintAuthToken:
  SyscallMintAuthTokenTrace mint_auth_token;
case kConsumeAuthToken:
  SyscallConsumeAuthTokenTrace consume_auth_token;
default:
  void;
};

union HostFunctionStatusXdr switch (HostFnErrorCode error)
{
case NoneOrRecoverable:
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
