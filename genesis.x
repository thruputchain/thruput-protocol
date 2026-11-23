// clang-format off
%#include "types.hh"
%#include "transaction.hh"
%#include "network_config.hh"
%#include "storage_cost.hh"
%#include "contract.hh"

namespace hogd {
// clang-format on

struct GenesisConfiguration {
  NetworkHash network_hash;
  StorageCostModelXdr storage_cost_model;

  /// The execution parameters block 0 runs under, in canonical form. Carried
  /// into the DbTip at genesis load and forward by every later commit.
  NetworkConfig network_config;
  Contract root_contract;

  /// The contract resolved for root invocations of undeployed addresses.
  /// Committed to by `ProposalHeader::config_hash` through
  /// `ConfigHashPreimage`, so a node cannot run under a different one than
  /// the chain agreed.
  DeployedContractHash default_wallet;
};

// These translated into the contract addresses that are initialized
// at the start of the chain.
//
// The addresses (32 bytes) are all zeros, with the last 4 bytes equal
// to the enum value.
enum GenesisContractAddresses {
  // Null address (reserved)
  kAddressNull = 0,
  // Precompiled native-token contract
  kAddressNativeToken = 1,
  // Genesis root contract
  kAddressGenesisRoot = 2
};

} // namespace hogd
