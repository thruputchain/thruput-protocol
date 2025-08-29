// clang-format off

%#include "types.hh"
%#include "transaction.hh"
%#include "genesis.hh"

namespace hogd {
  // clang-format on

  enum ExperimentType {
    kExperimentTypeERC20Payments = 0,
  };

  struct ERC20PaymentsConfig {
    unsigned hyper num_txs;
    unsigned hyper num_accounts;
  };

  union ExperimentConfig switch (ExperimentType experiment_type)
  {
  case kExperimentTypeERC20Payments:
    ERC20PaymentsConfig erc20_payments;
  };

  typedef SignedTransaction InitializationBlock<>;

  struct LoadgenSuccessResult {
    GenesisBlock genesis_block;
    InitializationBlock initialization_txs<>;
    SignedTransaction work_txs<>;
  };

  enum LoadgenRPCError {
    kLoadgenRPCErrorOK = 0,
    kLoadgenRPCErrorInvalidConfig = 1,
  };

  union LoadgenResult switch (LoadgenRPCError error)
  {
  case kLoadgenRPCErrorOK:
    LoadgenSuccessResult success;
  default:
    void;
  };

  program LoadgenInterface
  {
    version LoadgenInterfaceV1
    {
      LoadgenResult generate_experiment(ExperimentConfig) = 0;
    }
    = 1;
  }
  = 12341234;

} // namespace hogd
