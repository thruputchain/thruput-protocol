// clang-format off

%#include "types.hh"
%#include "contract.hh"
%#include "transaction.hh"
%#include "storage_item.hh"
%#include "rpc_types.hh"

namespace hogd
{
  // clang-format on

  union ExpectedStorageItem switch (RPCError error) {
  case kNone:
    StorageItem item;
  default:
    void;
  };

  union ExpectedContract switch (RPCError error) {
  case kNone:
    Contract contract;
  default:
    void;
  };

  union ExpectedDeployment switch (RPCError error) {
  case kNone:
    SHA256Hash deployed_hash;
  default:
    void;
  };

  program DatabaseSnapshotReadInterface {
    version DatabaseSnapshotReadInterfaceV1 {
      // Null rpc
      void db_snapshot_read_null(void) = 0;

      // Load the snapshot value of a storage item at the supplied address,
      // if it exists.
      ExpectedStorageItem get_snapshot_item(BlockID, AddressAndKey) = 1;

      // TODO(geoff) consider whether we want to combine these or not.
      // Tradeoff is messages vs maybe sending redundant contracts.
      // Perhaps the sender could cache whether it expects the client to have
      // the contract, and optionally send accordingly.
      ExpectedContract get_contract(BlockID, SHA256Hash) = 2;
      ExpectedDeployment get_deployment(BlockID, ContractAddress) = 3;
    }
    = 1;
  }
  = 44444444;

} // namespace hogd