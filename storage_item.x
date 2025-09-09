// clang-format off
%#include "types.hh"
%#include "retrocausal_queue.hh"
%#include "account.hh"

namespace hogd
{
  // clang-format on

  enum StorageItemType {
    kItemTypeBytestring = 0,
    kItemTypeNonnegativeInt = 1,
    kItemTypeRetrocausalQueue = 2,
    kItemTypeReplayCache = 3,
    kItemTypeAuthData = 4,
    kItemTypeDeleted = -1,
  };

  const kBytestringMaxLen = 1024;

  typedef opaque Bytestring<>;

  struct ReplayCacheMetadata {
    unsigned hyper minimum_threshold;
  };

  union StorageItem switch (StorageItemType type)
  {
  case kItemTypeBytestring:
    Bytestring bytestring;
  case kItemTypeNonnegativeInt:
    int128_xdr nnint;
  case kItemTypeRetrocausalQueue:
    void;
  case kItemTypeReplayCache:
    ReplayCacheMetadata replay_cache_metadata;
  };

  enum StorageDeltaType {
    kDeltaTypeBytestringSet = 0,
    kDeltaTypeNonnegativeIntSetAdd = 1,
    kDeltaTypeDelete = 2,
    kDeltaTypeRetrocausalQueue = 3,
    kDeltaTypeReplayCacheModify = 4,
    kDeltaTypeNonnegativeIntAdd = 5,
    kDeltaTypeAuthDataChangeSigner = 6,
  };

  struct AuthDataChangeSignerArgs {
    unsigned int public_key_id;
    PublicKey *public_key;
  };

  struct NonnegativeInt128SetAddArgs {
    int128_xdr set_value;
    int128_xdr add_value;
  };

  struct ReplayCacheModifyArgs {
    unsigned hyper minimum_threshold;
    ReplayNonce nonces<>;
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
  case kDeltaTypeReplayCacheModify:
    ReplayCacheModifyArgs replay_cache_modify;
  case kDeltaTypeAuthDataChangeSigner:
    AuthDataChangeSignerArgs auth_data_change_signer;
  };

} // namespace hogd
