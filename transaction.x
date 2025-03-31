
// clang-format off
%#include "types.hh"
%#include "contract.hh"

namespace hogd
{
  // clang-format on
  typedef opaque Calldata<>;

  typedef opaque ReturnBuffer<>;

  struct Invocation {
    ContractAddress invoked_address;
    unsigned int method;
    GasAmount gas_limit;
    Calldata calldata;
  };

  struct Transaction {
    Invocation invocation;
    Contract contracts_to_deploy<>;
  };

  // Deliberately leaving this SignedTransaction object
  // (and all the other metadata)
  // for a later PR.
  struct SignedTransaction {
    Transaction tx;
  };

  // Nondeterministic data attached to a transaction by the proposer.
  // Left empty until future PRs.
  struct NondeterministicProposalData {
    void;
  };

  // A signed transaction, with the nondeterministic data from the proposer
  // attached to it.
  struct ProposedTransaction {
    SignedTransaction signed_tx;
    NondeterministicProposalData nondeterministic_proposal_data;
  };

} // namespace hogd
