%#include "types.hh"
%#include "auth_claim.hh"
%#include "transaction.hh"
%#include "auth_token.hh"
%#include "invoke_flag.hh"
%#include "event.hh"

namespace hogd {

struct TransactionViewQuery {
  // The invocation to be queried
  Invocation invocation;

  // Context around the invocation
  ContractAddress *parent_address;
  AuthClaim auth_claim;
  AuthToken forwarded_tokens<>;
  InvokeFlagSet invoke_flags;

  // Intentionally not putting newly deployed contracts here, at least for now.
  // We do not want people flooding us with new contracts,
  // and new contracts start with empty state anyways -- this can be simulated locally.
  // This can be changed later, if we deem that necessary.
};

struct TransactionViewResult {
  // The result of the invocation
  InvocationFrameOutput output;

  // Gas the invocation consumed: the root frame and every frame it invoked.
  // On an out-of-gas fault it is the invocation's gas limit. A view attaches
  // no contracts, so this matches the gas_consumed a transaction making the
  // same invocation against the same state would commit in its TxEventLog.
  GasAmount gas_consumed;

  TxEmittedEvent events<>;
};

enum TransactionViewStatus {
  Ok = 0,
  // Block was abandoned (sibling block committed) during view execution.
  // View operation should be retried later.
  Abandoned = 1,
  // Internal error; should not happen.
  InternalError = 2,

  // Invalid input: i.e. reentrance guard violation.  Deterministic, but the frame does not start,
  // so no frame output is produced.
  InvalidInput = 3,

  // Validation failure: supplied nondeterministic data is somehow invalid,
  // such as requesting a queue entry that is not present.
  NondeterministicDataValidationFailure = 4
};

union ExpectedViewResult switch (TransactionViewStatus status) {
case Ok:
  TransactionViewResult result;
case InvalidInput:
  SyscallErrorCode error_code;
case Abandoned:
case InternalError:
case NondeterministicDataValidationFailure:
  void;
};

} // namespace hogd
