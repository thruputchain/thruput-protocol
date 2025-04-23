// clang-format off

%#include "types.hh"
%#include "contract.hh"
%#include "transaction.hh"
%#include "storage_item.hh"
%#include "rpc_types.hh"

namespace hogd
{
  // clang-format on

  program DatabaseToExecutorInterface {
    version DatabaseToExecutorInterfaceV1 {
      // Warning: the returned marginal storage cost may be nondeterministic.
      ExpectedStorageCost try_reserve_delta(BlockID, TransactionID,
                                            AddressAndKey, StorageDelta,
                                            StorageItemRPCFlagSet) = 0;
      void commit_transaction(BlockID, TransactionID) = 1;
      void abort_transaction(BlockID, TransactionID) = 2;

      // Load the snapshot value of a storage item at the supplied address,
      // if it exists.
      ExpectedStorageItem get_snapshot_item(BlockID, AddressAndKey) = 3;

      // Create a new contract.
      // Arguments:
      //   New Contract
      void commit_contract_create(BlockID, Contract) = 4;

      // Create a new deployment.
      // Arguments:
      //   ContractAddress
      //   SHA256Hash of contract to be deployed
      void commit_contract_deploy(BlockID, ContractAddress, SHA256Hash) = 5;

      // TODO(geoff) consider whether we want to combine these or not.
      // Tradeoff is messages vs maybe sending redundant contracts.
      // Perhaps the sender could cache whether it expects the client to have
      // the contract, and optionally send accordingly.
      ExpectedContract get_contract(BlockID, SHA256Hash) = 6;
      ExpectedDeployment get_deployment(BlockID, ContractAddress) = 7;
    }
    = 1;
  }
  = 44444444;

} // namespace hogd