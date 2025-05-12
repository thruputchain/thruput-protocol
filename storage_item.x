// clang-format off
%#include "types.hh"
%#include "retrocausal_queue.hh"

namespace hogd
{
  // clang-format on

  enum StorageItemType {
    kItemTypeBytestring = 0,
    kItemTypeNonnegativeInt = 1,
    kItemTypeRetrocausalQueue = 2,
    kItemTypeAssetBalance = 3,
    kItemTypeDeleted = -1,
  };

  const kBytestringMaxLen = 1024;

  typedef opaque Bytestring<>;

  union StorageItem switch (StorageItemType type)
  {
  case kItemTypeBytestring:
    Bytestring bytestring;
  case kItemTypeNonnegativeInt:
    int128_xdr nnint;
  case kItemTypeRetrocausalQueue:
    void;
  case kItemTypeAssetBalance:
    uint128_xdr asset_balance;
  };

  enum StorageDeltaType {
    kDeltaTypeBytestringSet = 0,
    kDeltaTypeNonnegativeIntSetAdd = 1,
    kDeltaTypeDelete = 2,
    kDeltaTypeRetrocausalQueue = 3,
    kDeltaTypeAssetTransfer = 4,
  };

  struct NonnegativeInt128SetAddArgs {
    int128_xdr set_value;
    int128_xdr add_value;
  };

  union StorageDelta switch (StorageDeltaType type)
  {
  case kDeltaTypeBytestringSet:
    Bytestring bytestring;
  case kDeltaTypeNonnegativeIntSetAdd:
    NonnegativeInt128SetAddArgs nnint;
  case kDeltaTypeDelete:
    void;
  case kDeltaTypeRetrocausalQueue:
    RetrocausalQueueDelta retrocausal_queue;
  case kDeltaTypeAssetTransfer:
    int128_xdr transfer_amount;
  };

} // namespace hogd
