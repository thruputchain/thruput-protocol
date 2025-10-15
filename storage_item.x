// clang-format off
%#include "types.hh"
%#include "retrocausal_queue.hh"
%#include "account.hh"
%#include "transaction.hh"

namespace hogd
{
// clang-format on

enum StorageItemType {
  kItemTypeBytestring = 0,
  kItemTypeNonnegativeInt = 1,
  kItemTypeRetrocausalQueue = 2,
  kItemTypeReplayCacheData = 3,
  kItemTypeAuthData = 4,
  kItemTypeDeployedContractHash = 5,
  kItemTypeDeleted = -1,
};

const kBytestringMaxLen = 1024;

typedef opaque Bytestring<>;

// TODO(stutsman) use name ReplayCache instead and update storage_item instead?
struct ReplayCacheData {
  Uniquifier uniquifiers<>;
};

// This represents the contents of storage item that are sent over the wire
// to the executor.  We do not send the entire contents of the database over to the executor.
union StorageItem switch (StorageItemType type)
{
case kItemTypeBytestring:
  Bytestring bytestring;
case kItemTypeNonnegativeInt:
  int128_xdr nnint;
case kItemTypeRetrocausalQueue:
  void;
case kItemTypeReplayCacheData:
  void;
case kItemTypeAuthData:
  AccountAuthData auth_data;
case kItemTypeDeployedContractHash:
  DeployedContractHash deployed_contract_hash;
};

enum StorageDeltaType {
  kDeltaTypeBytestringSet = 0,
  kDeltaTypeNonnegativeIntSetAdd = 1,
  kDeltaTypeDelete = 2,
  kDeltaTypeRetrocausalQueue = 3,
  kDeltaTypeNonnegativeIntAdd = 5,
  kDeltaTypeAuthDataChange = 6,
  kDeltaTypeDeployContract = 7,
  kDeltaTypeConsumeUniquifier = 8,
};

struct AuthDataChangeSigner {
  unsigned int public_key_id;
  PublicKeyConfigOpt public_key;
};

struct AuthDataChangeArgs {
  AuthDataChangeSigner auth_data_change_signers<>;
};

struct NonnegativeInt128SetAddArgs {
  int128_xdr set_value;
  int128_xdr add_value;
};

struct ConsumeUniquifierArgs {
  Uniquifier uniquifier;
};

union StorageDelta switch (StorageDeltaType type)
{
case kDeltaTypeBytestringSet:
  Bytestring bytestring;
case kDeltaTypeNonnegativeIntSetAdd:
  NonnegativeInt128SetAddArgs nnint;
case kDeltaTypeNonnegativeIntAdd:
  int128_xdr nnint_add;
case kDeltaTypeDelete:
  void;
case kDeltaTypeRetrocausalQueue:
  RetrocausalQueueDelta retrocausal_queue;
case kDeltaTypeAuthDataChange:
  AuthDataChangeArgs auth_data_change;
case kDeltaTypeDeployContract:
  DeployedContractHash deployed_contract_hash;
case kDeltaTypeConsumeUniquifier:
  ConsumeUniquifierArgs consume_uniquifier_args;
};

} // namespace hogd
