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

      // Subtransaction control methods.
      // Subtransactions do not need their own unique IDs; every write from a transaction
      // must always be applied to the top-level subtransaction.
      // 
      // Create a new subtransaction on top of the current (sub)transaction.
      void push_new_subtransaction(BlockID, TransactionID) = 3;
      
      // Revert one or more subtransactions.
      void pop_subtransactions(BlockID, TransactionID, unsigned int) = 4;

      // Load the snapshot value of a storage item at the supplied address,
      // if it exists.
      ExpectedStorageItem get_snapshot_item(BlockID, AddressAndKey) = 100;

      // Create a new contract.
      // Arguments:
      //   New Contract
      void commit_contract_create(BlockID, Contract) = 101;

      // Create a new deployment.
      // Arguments:
      //   ContractAddress
      //   SHA256Hash of contract to be deployed
      void commit_contract_deploy(BlockID, ContractAddress, SHA256Hash) = 102;

      // TODO(geoff) consider whether we want to combine these or not.
      // Tradeoff is messages vs maybe sending redundant contracts.
      // Perhaps the sender could cache whether it expects the client to have
      // the contract, and optionally send accordingly.
      ExpectedContract get_contract(BlockID, SHA256Hash) = 103;
      ExpectedDeployment get_deployment(BlockID, ContractAddress) = 104;
    }
    = 1;
  }
  = 44444444;

} // namespace hogd