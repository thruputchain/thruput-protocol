// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]
typedef SHA256Hash ConsensusBasisHash; // #[rust(newtype)]

struct ConsensusBasis {
  TimePoint timestamp;
  ValidatorID proposer;
  Nomination nomination;
  Upgrade upgrades<6>;
  ConsensusValueHash prev_value_hash;
  ConsensusBasisHash prev_basis_hash;
};

typedef ConsensusBasis *OptConsensusBasis;


struct ConsensusValue {
  TimePoint timestamp;
  ValidatorID proposer;
  Upgrade upgrades<6>;
  BlockHeight block_height;
  ConsensusValueHash prev_value;
  ConsensusBasisHash basis_hash;
  ConsensusBasisHash prev_basis_hash;
  BlockHash block_hash;
  BlockHash prev_block_hash;
};

} // namespace hogd
