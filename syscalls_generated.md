<!-- Generated from syscalls.yaml by generate_syscalls_doc.py; do not edit. -->

All syscalls can return error kFault if a user-supplied argument points to an
invalid contract memory address.

All syscalls that return a bytespan of non-static size (a [u8], as written
here) take as one of their arguments a contract-allocated bytespan, in which
the output argument should be written, AND return a RuntimeMemoryLength
variable, which describes the full length of the output. At most bytespan.len()
bytes are written into the contract-supplied bytespan; if the returned length
is greater than bytespan.len(), the output did not fit and was truncated, and
the contract should retry with a buffer of at least the returned length. We do
not change any of the remaining elements of the bytespan.


# SHA256

## Signature
SHA256(buffer: [u8]) -> SHA256Hash

## Description
Returns the SHA256 hash of the input buffer.

## Errors
- Does not return additional errors.


# GetMsgSender

## Signature
GetMsgSender() -> ContractAddress

## Description
Returns the contract address of the contract that invoked the current call frame.

## Errors
- kSyscallErrorCodeIsRootTransaction:
  The syscall was called from a root transaction. There is no caller address in this case.


# GetCalldataLen

## Signature
GetCalldataLen() -> (RuntimeMemoryLength, u32)

## Description
Returns the length of the calldata supplied to the invocation associated with the current call frame. Also returns the number N of auth tokens supplied to the invocation, which are the current frame's auth token ids 0..N-1.

## Errors
- Does not return additional errors.


# GetCalldata

## Signature
GetCalldata() -> ([u8], RuntimeMemoryLength, u32)

## Description
Returns the calldata supplied to the invocation associated with the current call frame.
written_len is the full length of the calldata, not the number of bytes copied: at most buffer.len() bytes are written, and a written_len greater than buffer.len() means the output was truncated.
Also returns the number N of auth tokens supplied to the invocation. Auth token ids are local to each call frame, and the supplied tokens are the current frame's ids 0..N-1, in the order the caller listed them.

## Errors
- Does not return additional errors.


# ConsoleLog

## Signature
ConsoleLog(buffer: [u8]) -> ()

## Description
Logs the input buffer to the console. This is a no-op on release builds or when deployed on-chain.
This will not cause an error if a contract inadvertently includes this syscall in a production contract deployment (if, for example, a contract built in debug mode is uploaded), but there is no reason to do so.

## Errors
- Does not return additional errors.


# Invoke

## Signature
Invoke(
  address: ContractAddress,
  calldata: [u8],
  owned_auth_token_ids_list: [u8],
  inputs: CopyableInvokeInputs) -> CopyableInvokeOutputs

## Description
Invokes the specified method of the contract at the specified
address, with the supplied parameters. Creates a new invocation
frame, which terminates upon conclusion of the Invoke() syscall.
The frame will be limited to the minimum of gas_limit units
of gas and the remaining gas in the current frame.
The SDK sets the default gas limit as UINT64_MAX, meaning i.e.
all of the remaining gas in the current frame.
Any unused gas will be returned to the caller.
The entrypoint is the entrypoint_id field of inputs, a u64 holding the
big-endian interpretation of the ContractEntrypointID ([u8; 8]) bytes
(ContractEntrypointID::into_u64 in the Rust bindings).
The list of auth tokens is passed as a span, which should be
interpreted as a [u32] slice.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The invocation was rejected before any child frame ran: the contract was not found, the invoke flags were invalid, the calldata is longer than kConfigParamMaxCalldataLen, more auth token ids were supplied than kConfigParamMaxAuthTokens, or one or more of the supplied auth token ids are malformed, duplicated, or not owned by the current frame. The syscall is a complete no-op in this case.
- kSyscallErrorCodeReentrance:
  The invoked address is already on the stack. The invocation is rejected before any child frame runs and the syscall is a no-op.
- kSyscallErrorCodeInvokeDepthExceeded:
  The transaction already holds kConfigParamMaxCrossInvokeDepth invocation frames open, so admitting another would exceed the network's cross-invoke depth bound. This is a resource limit rather than a malformed call -- the same invocation succeeds from a shallower frame. The invocation is rejected before any child frame runs and the syscall is a no-op.


# Return

## Signature
Return(
  buffer: [u8],
  revert_frame: bool,
  returned_auth_token_ids: [u8]) -> !

## Description
Returns data from the current call frame and optionally marks the frame for revert. The return buffer will be available to the caller via GetReturnedBuffer. Immediately terminates execution of the current invocation.
The syscall never returns an error. Instead, the frame faults with a deterministic error (equivalent to Exit) if the buffer is longer than kConfigParamMaxReturnBufferLen, if auth tokens are returned from a frame marked for revert, or if the returned auth token id list is longer than kConfigParamMaxAuthTokens, malformed, duplicated, or names tokens the current frame does not own.

## Errors
- Does not return additional errors.


# GetReturnedBuffer

## Signature
GetReturnedBuffer() -> ([u8], RuntimeMemoryLength, u32, u32)

## Description
Returns the return buffer from the most recent subcall invocation that ended with Return, including a Return that marked the frame for revert.
written_len is the full length of the return buffer, not the number of bytes copied: at most buffer.len() bytes are written, and a written_len greater than buffer.len() means the output was truncated.
Also returns the auth tokens that subcall returned, as the current frame's auth token ids start..start+count-1. The returned tokens join the frame under consecutive new ids, in the order the subcall listed them.

## Errors
- kSyscallErrorCodeNoReturnBufferAvailable:
  No return buffer is available. Either the most recent subcall faulted (for example by trapping or calling Exit), or there have been no subcalls within this call frame.


# Exit

## Signature
Exit() -> !

## Description
Terminates execution of the current call frame immediately. The current call frame reverts, returning a deterministic error to the caller (with no return buffer available). Equivalent to a guest trap.

## Errors
- Does not return additional errors.


# GetDeployAddress

## Signature
GetDeployAddress(
  caller_address: Option<ContractAddress>,
  nonce: SHA256Hash,
  contract_hash: SHA256Hash) -> ContractAddress

## Description
Computes the address that would be deployed for a contract with the given deployer address, nonce, and contract hash. This is a pure computation and does not actually deploy the contract. If caller_address is omitted, the current contract's address is used, giving the address DeployContract would use.

## Errors
- Does not return additional errors.


# DeployContract

## Signature
DeployContract(
  nonce: SHA256Hash,
  contract_hash: SHA256Hash) -> ContractAddress

## Description
Deploys a contract with the specified nonce and contract hash to a computed address. The contract must be provided in the transaction's contracts_to_deploy field.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The requested contract was not available for deployment, or the contract is a special precompiled (native) contract that cannot be deployed (i.e. the native token contract).
To deploy a contract, that contract must either already exist on chain or must be provided in the transaction's contracts_to_deploy field.
- kSyscallErrorCodeContractAlreadyDeployed:
  A contract with the same nonce and contract hash has already been deployed at the computed address, either in a previous block or earlier in this transaction.
A contract can be deployed multiple times concurrently in the same block.  If a contract must be initialized only once, then that contract should run some initialization process and that initialization should acquire a semaphore.


# GetSourceTransactionHash

## Signature
GetSourceTransactionHash() -> SHA256Hash

## Description
Returns the hash of the transaction that initiated the current execution: sha256 of the XDR-encoded Transaction, the same TransactionHash that identifies it network-wide.

## Errors
- Does not return additional errors.


# VerifySignature

## Signature
VerifySignature(
  scheme: i32,
  signature: [u8],
  public_key: [u8],
  message: [u8]) -> ()

## Description
Verifies a cryptographic signature against a public key and message. Returns kSyscallErrorCodeNone if verification succeeds, otherwise returns an error.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The signature verification failed, or the input parameters are invalid (e.g., incorrect key/signature size for the specified scheme, or unsupported scheme).


# BytestringGetLen

## Signature
BytestringGetLen(key: StorageKeyContractData) -> RuntimeMemoryLength

## Description
Returns the length of the bytestring stored at the specified key.

## Errors
- kSyscallErrorCodeStorageKeyNotExist:
  The storage key does not exist in the current transaction's view.
- kSyscallErrorCodeInvalidSyscallInput:
  The storage key exists but contains a different type (e.g., NNInt instead of bytestring).


# BytestringGet

## Signature
BytestringGet(key: StorageKeyContractData) -> ([u8], RuntimeMemoryLength)

## Description
Retrieves the bytestring stored at the specified key.
written_len is the full length of the bytestring, not the number of bytes copied: at most bytestring.len() bytes are written, and a written_len greater than bytestring.len() means the output was truncated.

## Errors
- kSyscallErrorCodeStorageKeyNotExist:
  The storage key does not exist or has been deleted.
- kSyscallErrorCodeInvalidSyscallInput:
  The storage key exists but contains a different type (e.g., NNInt instead of bytestring).


# BytestringSet

## Signature
BytestringSet(
  key: StorageKeyContractData,
  bytestring: [u8]) -> ()

## Description
Sets the bytestring value at the specified storage key. Note that this will overwrite any existing value at that key, *even if* that value has a different type.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The bytestring is too long.


# NonnegativeIntGet

## Signature
NonnegativeIntGet(
  key: StorageKeyContractData,
  force_load_from_snapshot: bool) -> (i128, bool, i128)

## Description
Retrieves the nonnegative integer value at the specified storage key.
current_set_opt reports whether current_set holds a value; when it is false, current_set carries no information and should be ignored.
If force_load_from_snapshot is true, then current_set_opt is always true on success. If the snapshot value is not an NNInt, or the previous write on that key was not an NNInt, then the syscall returns kSyscallErrorCodeInvalidSyscallInput. If the snapshot value does not exist, or has been deleted by the prior write, then it returns kSyscallErrorCodeStorageKeyNotExist.
If force_load_from_snapshot is false, then the prior state of the item is ignored unless the prior write on that key is an NNInt write (in which case the parameters of that write are returned). If the prior write is not an NNInt, or was a deletion, then current_set_opt is false and current_add is 0.

## Errors
- kSyscallErrorCodeStorageKeyNotExist:
  The storage key does not exist or has been deleted. Only returned if force_load_from_snapshot is true.
- kSyscallErrorCodeInvalidSyscallInput:
  The storage key exists but contains a different type (e.g., bytestring instead of NNInt). Only returned if force_load_from_snapshot is true.


# NonnegativeIntSetAdd

## Signature
NonnegativeIntSetAdd(
  key: StorageKeyContractData,
  set_value: Option<i128>,
  add_value: i128) -> ()

## Description
Sets or modifies a nonnegative integer at the specified storage key. The set_value (if provided) sets the base value, and add_value is added as a delta. The final value must remain nonnegative. Will overwrite any value of that key, *even if* that value has a different type.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The operation would always result in a negative value (i.e. set_add(1, -2)).


# DeleteObject

## Signature
DeleteObject(key: StorageKeyContractData) -> ()

## Description
Deletes the object at the specified storage key.

## Errors
- Does not return additional errors.


# GetCurrentAddress

## Signature
GetCurrentAddress() -> ContractAddress

## Description
Returns the contract address of the current call frame.

## Errors
- Does not return additional errors.


# RetrocausalQueueInsert

## Signature
RetrocausalQueueInsert(
  key: StorageKeyContractData,
  queue_entry: [u8]) -> ()

## Description
Inserts an entry into the retrocausal queue at the specified storage key. Like any storage write, this replaces a value of another type at the key. A queue with no live entries does not exist.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The queue entry is too large, or too many entries are inserted in the current transaction.


# RetrocausalQueueConsume

## Signature
RetrocausalQueueConsume(
  key: StorageKeyContractData,
  peek: bool) -> ([u8], RuntimeMemoryLength)

## Description
Consumes (or peeks at) the next entry from the retrocausal queue at the specified storage key. If peek is true, the entry is not removed from the queue. A read never changes the type of the key; a same-block conversion by another transaction is visible only from the next block.
written_len is the full length of the entry, not the number of bytes copied: at most queue_entry.len() bytes are written, and a written_len greater than queue_entry.len() means the output was truncated. A consumed entry is removed even if it was truncated, so size queue_entry with RetrocausalQueuePeekLen first.

## Errors
- kSyscallErrorCodeNoRetrocausalQueueEntry:
  The retrocausal queue is empty and has no entries to consume.
- kSyscallErrorCodeInvalidSyscallInput:
  The storage key exists but contains a different type.
- kSyscallErrorCodeRetrocausalQueueReadLimitReached:
  The transaction has read the maximum number of concurrent retrocausal-queue entries allowed per transaction. Returning this does not fail the transaction; a contract may use it as a stop condition.


# GetTransactionStatistics

## Signature
GetTransactionStatistics(statistic: TransactionStatistic) -> u64

## Description
Returns a transaction statistic value. Note that statistics may be disabled in release builds or production execution, and may return nondeterministic values in test configurations. Nondeterministic stats will be disabled in production settings.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The requested statistic does not exist or is not available in this configuration.


# ChangePublicKeyRegistration

## Signature
ChangePublicKeyRegistration(
  key_index: u32,
  key_scheme: Option<i32>,
  key_bytes: [u8],
  key_weight: Option<u32>) -> ()

## Description
Changes the public key registration for the current contract address at the specified key index. If key_scheme is None, the key is removed. Otherwise, the key is set with the provided scheme, bytes, and weight.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The public key registration is invalid, or the input key index is out of bounds.


# LogEvent

## Signature
LogEvent(
  topic0: Option<[u8; 32]>,
  topic1: Option<[u8; 32]>,
  topic2: Option<[u8; 32]>,
  data: [u8]) -> ()

## Description
Logs an event with up to 3 topics and additional data. Constructs a TxEmittedEvent where the serialized_event field contains the topics prepended to the data: topic0 || topic1 || topic2 || data. The num_topics field indicates how many leading 32-byte chunks are topics, enabling downstream indexers to efficiently filter events. Events are stored in the transaction's event log and accumulated into a per-block merkle-patricia trie.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The serialized event (32 bytes per supplied topic plus the data) is longer than kMaxEventLength, the transaction has already emitted kMaxEventsPerTransaction events, or topics are not supplied in a continuous sequence (e.g., topic0 and topic2 provided without topic1).


# GetAuthClaim

## Signature
GetAuthClaim() -> AuthClaim

## Description
Returns the authentication claim associated with the current transaction.

## Errors
- Does not return additional errors.


# SHA256Update

## Signature
SHA256Update(
  index: u32,
  buffer: [u8],
  reset: bool) -> ()

## Description
Updates the SHA256 hash computation at the specified index with the provided buffer. If reset is true, the hash input is reset before updating. The buffer must exist if reset is false. There is no cumulative byte limit.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  This error will be returned if any of the following
conditions are met:
- The queried hash buffer does not exist and reset is false.
- There are too many active hash buffers.


# SHA256Finalize

## Signature
SHA256Finalize(index: u32) -> SHA256Hash

## Description
Finalizes the SHA256 hash computation at the specified index and returns the hash. Removes the hash buffer after finalization.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  Returns an error if the queried hash buffer does not exist. For example, if finalize is called twice on the same buffer without an intervening reset, then the second call will return this error.


# WriteAddressRequiredWeight

## Signature
WriteAddressRequiredWeight(required_weight: u32) -> ()

## Description
Writes the required weight threshold for the current contract address. This is the minimum total weight of signing keys needed to authorize a transaction from this address.

## Errors
- Does not return additional errors.


# GetBlockHeight

## Signature
GetBlockHeight() -> BlockHeight

## Description
Returns the current block height.

## Errors
- Does not return additional errors.


# RetrocausalQueuePeekLen

## Signature
RetrocausalQueuePeekLen(key: StorageKeyContractData) -> RuntimeMemoryLength

## Description
Returns the byte length of the next entry in the retrocausal queue at the specified storage key, without consuming it: the queue_entry buffer size RetrocausalQueueConsume needs to read that entry whole.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The storage key exists but contains a different type.
- kSyscallErrorCodeNoRetrocausalQueueEntry:
  The retrocausal queue is empty and has no entries to peek.
- kSyscallErrorCodeRetrocausalQueueReadLimitReached:
  The transaction has read the maximum number of concurrent retrocausal-queue entries allowed per transaction. Returning this does not fail the transaction; a contract may use it as a stop condition.


# MintAuthToken

## Signature
MintAuthToken(
  expiry_height: BlockHeight,
  serialized_auth_token: [u8]) -> u32

## Description
Mints an authentication token for the current contract address.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The serialized authentication token fails to parse as a valid AuthToken, expiry height is in the past, or the number of auth tokens minted would exceed the maximum for the transaction.


# ConsumeAuthToken

## Signature
ConsumeAuthToken(token_id: u32) -> ([u8], ContractAddress, RuntimeMemoryLength, u32, u32)

## Description
Consumes an authentication token for the current contract address. Returns any nested tokens unwrapped by the token.
auth_payload_written_len is the full length of the token's payload, not the number of bytes copied: at most auth_payload.len() bytes are written, and a larger value means the payload was truncated. The token is consumed either way, so a truncated payload cannot be read again.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The authentication token is not owned by the current contract address, or the auth token has expired.


# SHA256Copy

## Signature
SHA256Copy(
  src_index: u32,
  dst_index: u32) -> ()

## Description
Copies the in-progress SHA256 hash computation at src_index to dst_index, replacing any hash computation already at dst_index. Both computations can then be extended and finalized independently. Copying an index onto itself succeeds and changes nothing.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  This error will be returned if any of the following
conditions are met:
- The hash computation at src_index does not exist.
- dst_index does not already hold a hash computation and
  there are too many active hash buffers.


# GetNetworkHash

## Signature
GetNetworkHash() -> NetworkHash

## Description
Returns the hash of the network name, the identifier that separates this network's blocks from those of every other network. It is fixed for the life of the network, so it is constant across every block and every invocation.
Transaction signatures already commit to this value (the signature preimage is `cxs(DomainSeparator("Transaction")) || network_hash || xdr(tx)`). Exposing it to contracts lets a contract bind its own off-chain signed messages to this network the same way, so a message signed for one network cannot be replayed against a contract at the same address on another.

## Errors
- Does not return additional errors.


# GetBlockTimepoint

## Signature
GetBlockTimepoint() -> TimePoint

## Description
Returns the timepoint of the block currently executing. The value is fixed by the coordinator before execution begins and is carried in the block's ProposalHeader, so it is part of the block identity and is identical for every invocation in the block.
Like a block height, this is consensus data rather than a trusted clock: it is chosen by the proposer within whatever bounds the network's validators enforce. Contracts should treat it as coarse-grained wall-clock time -- suitable for expiries, vesting schedules and deadlines -- and must not rely on it for fine-grained ordering or as a source of randomness.

## Errors
- Does not return additional errors.


# SetStorageFlags

## Signature
SetStorageFlags(
  key: StorageKeyContractData,
  flags: StorageDeltaFlagSet) -> ()

## Description
Adds flags (a bitwise OR) to the storage flags the current transaction requests for the key. Writes never change a key's flags: every change the transaction commits on the key carries the flags accumulated here, whichever write produced it. ClearStorageFlags removes them.
A write to the key must be pending in the current call frame's view of the transaction: one made earlier in this frame, or inherited from a caller or from a successful callee. A pending deletion qualifies; a value that exists only in the block snapshot does not. Flags set in a frame that aborts are discarded along with that frame's writes.

## Errors
- kSyscallErrorCodeInvalidSyscallInput:
  The flags are invalid, or no write to the key is pending in the current call frame's view of the transaction.


# GetStorageFlags

## Signature
GetStorageFlags(key: StorageKeyContractData) -> StorageDeltaFlagSet

## Description
Returns the storage flags the current transaction requests for the key, as visible in the current call frame. A key with no pending write has no flags, so it reads as StorageDeltaFlags::None, the same as a pending write without flags.

## Errors
- Does not return additional errors.


# ClearStorageFlags

## Signature
ClearStorageFlags(key: StorageKeyContractData) -> ()

## Description
Clears every storage flag the current transaction requests for the key, as visible in the current call frame. Does nothing if no write to the key is pending, since such a key has no flags. As with SetStorageFlags, a clear made in a frame that aborts is discarded with that frame.

## Errors
- Does not return additional errors.

