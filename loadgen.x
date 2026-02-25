// clang-format off

%#include "parallel.hh"
%#include "types.hh"
%#include "transaction.hh"
%#include "genesis.hh"

namespace hogd {
// clang-format on

enum ExperimentType {
  kExperimentTypeERC20Payments = 0,
  kExperimentTypeERC20BasicAuthPayments = 1,
};

struct ERC20PaymentsConfig {
  unsigned hyper num_addresses;
};

union ExperimentConfig switch (ExperimentType experiment_type)
{
case kExperimentTypeERC20Payments:
case kExperimentTypeERC20BasicAuthPayments:
  ERC20PaymentsConfig erc20_payments;
};

typedef SignedTransaction InitializationBlock<>;
typedef unsigned hyper LoadgenContextID;

struct LoadgenSuccessResult {
  GenesisConfiguration genesis_configuration;
  InitializationBlock initialization_txs<>;
  LoadgenContextID context_id;
};

struct LoadgenExtension {
  ParallelSignedTransactionBatch work_txs;
};

enum LoadgenRPCError {
  kLoadgenRPCErrorOK = 0,
  kLoadgenRPCErrorInvalidConfig = 1,
  kLoadgenRPCErrorInvalidContext = 2
};

union LoadgenResult switch (LoadgenRPCError error)
{
case kLoadgenRPCErrorOK:
  LoadgenSuccessResult success;
default:
  void;
};

union LoadgenExtensionResult switch (LoadgenRPCError error)
{
case kLoadgenRPCErrorOK:
  LoadgenExtension success;
default:
  void;
};

program LoadgenInterface
{
  version LoadgenInterfaceV1
  {
    LoadgenResult generate_experiment(ExperimentConfig) = 0;
    // arguments:
    // LoadgenContextID context_id (a handle returned by generate_experiment)
    // unsigned hyper num_txs (the number of transactions to return)
    // BlockHeight expiry_height (the height at which the transactions will expire)
    LoadgenExtensionResult extend_experiment(LoadgenContextID,
					     unsigned hyper,
					     BlockHeight) = 1;
  }
  = 1;
}
= 12341234;

} // namespace hogd
