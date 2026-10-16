// clang-format off
%#include "genesis.hh"
%#include "header.hh"
%#include "transaction.hh"

namespace hogd {
// clang-format on

/// The inputs to the genesis ceremony: the genesis configuration, the
/// proposal context of the genesis block, and the transactions the genesis
/// block executes.
///
/// A coordinator reads it from the file named by `coordinator start
/// --genesis`, and runs the ceremony through its scheduler (see
/// SchedulerCoord1 in sched_coord.x) when the scheduler has no genesis
/// block yet. Every validator of a network must run the ceremony with the
/// same prior, since the genesis value it produces is the one the whole
/// network's consensus starts from.
struct GenesisPrior {
  GenesisConfiguration config;
  ProposalContext ctx;
  SignedTransaction txs<>;
};

} // namespace hogd
