// clang-format off
%#include "config.hh"

namespace hogd {
// clang-format on

/// The router of a coordinator's boundary, which chooses the dissemination
/// trees over the validators the boundary knows.
struct CoordinatorRouterConfig {
  /// The largest number of children of a node of a dissemination tree.
  unsigned hyper max_fanout;
};

/// The baton, which drives a coordinator's proposals and validations
/// through its scheduler.
struct CoordinatorBatonConfig {
  /// The expected maximum local clock skew between validators.
  Milliseconds clock_skew_msec;
};

/// The consensus protocol a coordinator's broker runs.
struct CoordinatorConsensusConfig {
  /// The number of slots in an epoch: the leader elected for an epoch
  /// proposes for all of its slots. Must be positive.
  unsigned hyper epoch_length;
  /// The pipeline width: how many slots ahead of the current slot the
  /// leader may propose. Must be positive.
  unsigned hyper pipeline_length;
  /// The time a slot is given to resolve before it is deemed late.
  Milliseconds timeout_msec;
};

/// The basis and block pools of a coordinator. Each keeps the values of
/// the latest heights in memory and evicts older ones to disk after a
/// commit.
struct CoordinatorPoolConfig {
  /// How many heights below the committed tip the basis pool keeps in
  /// memory.
  unsigned hyper basis_pool_hotcold_window;
  /// How many heights below the committed tip the block pool keeps in
  /// memory.
  unsigned hyper block_pool_hotcold_window;
};

/// The configuration of a coordinator: what its command line reads from
/// the file named by `coordinator start --config`.
struct CoordinatorConfig {
  CoordinatorRouterConfig router;
  DogwoodConfig dogwood;
  CoordinatorBatonConfig baton;
  CoordinatorConsensusConfig consensus;
  CoordinatorPoolConfig pool;
};

} // namespace hogd
