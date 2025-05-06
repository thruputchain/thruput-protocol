// clang-format off

%#include "types.hh"
%#include "contract.hh"
%#include "transaction.hh"
%#include "storage_item.hh"
%#include "rpc_types.hh"

namespace hogd
{
  // clang-format on

  program DatabaseToExecutorInterface
  {
    version DatabaseToExecutorInterfaceV1
    {
      // Warning: the returned marginal storage cost may be nondeterministic.
      ExpectedStorageCost try_reserve_delta(BlockID, TransactionID,
                                            AddressAndKey, StorageDelta,
                                            StorageItemRPCFlagSet) = 0;
      RPCError commit_transaction(BlockID, TransactionID) = 1;
      RPCError abort_transaction(BlockID, TransactionID) = 2;

      // Subtransaction control methods.
      // Subtransactions do not need their own unique IDs; every write from a
      // transaction must always be applied to the top-level subtransaction.
      //
      // Create a new subtransaction on top of the current (sub)transaction.
      RPCError push_new_subtransaction(BlockID, TransactionID) = 3;

      // Revert one or more subtransactions.
      RPCError pop_subtransactions(BlockID, TransactionID, unsigned int) = 4;

      // Load the snapshot value of a storage item at the supplied address,
      // if it exists.
      ExpectedStorageItem get_snapshot_item(BlockID, AddressAndKey) = 100;

      // Returns the next block in the retrocausal queue at or after the
      // supplied block number. Returns kNoRetrocausalQueueBlock if there is no
      // element in the queue at or after the supplied block number (and before
      // the current block number).  Does not return data from the current
      // block, (the retrocausal part), which should be accessed via
      // get_concurrent_retrocausal_queue_entry().
      ExpectedRetrocausalQueueBlock get_next_retrocausal_queue_block(
          BlockID, AddressAndKey, unsigned hyper) = 101;

      // Returns the next unconsumed entry in the retrocausal queue for the
      // current block. The last argument is the index of the entry to return.
      // The queried order is nondeterministic.
      ExpectedQueueEntry get_concurrent_retrocausal_queue_entry(BlockID,
                                                                AddressAndKey,
                                                                unsigned int) =
          102;

      // Create a new contract.
      // Arguments:
      //   New Contract
      RPCError commit_contract_create(BlockID, Contract) = 200;

      // Create a new deployment.
      // Arguments:
      //   ContractAddress
      //   SHA256Hash of contract to be deployed
      RPCError commit_contract_deploy(BlockID, ContractAddress, SHA256Hash) =
          201;

      // TODO(geoff) consider whether we want to combine these or not.
      // Tradeoff is messages vs maybe sending redundant contracts.
      // Perhaps the sender could cache whether it expects the client to have
      // the contract, and optionally send accordingly.
      ExpectedContract get_contract(BlockID, SHA256Hash) = 202;
      ExpectedDeployment get_deployment(BlockID, ContractAddress) = 203;
    }
    = 1;
  }
  = 44444444;

} // namespace hogd
