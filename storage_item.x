// clang-format off
%#include "types.hh"
%#include "retrocausal_queue.hh"

namespace hogd
{
  // clang-format on

  enum StorageItemType {
    kBytestring = 0,
    kNonnegativeInt = 1,
    kRetrocausalQueue = 2,
    kDeleted = -1,
  };

  const kBytestringMaxLen = 1024;

  typedef opaque Bytestring<>;

  union StorageItem switch (StorageItemType type)
  {
  case kBytestring:
    Bytestring bytestring;
  case kNonnegativeInt:
    int128_xdr nnint;
  };

  enum StorageDeltaType {
    kBytestringSet = 0,
    kNonnegativeIntSetAdd = 1,
    kDelete = 2,
    kRetrocausalQueue = 3,
  };

  struct NonnegativeInt128SetAddArgs {
    int128_xdr set_value;
    int128_xdr add_value;
  };

  union StorageDelta switch (StorageDeltaType type)
  {
  case kBytestringSet:
    Bytestring bytestring;
  case kNonnegativeIntSetAdd:
    NonnegativeInt128SetAddArgs nnint;
  case kDelete:
    void;
  case kRetrocausalQueue:
    RetrocausalQueueDelta retrocausal_queue;
  };

} // namespace hogd
