// clang-format off
%#include "nomination.hh"
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

typedef opaque Upgrade<128>;

// The hash of a BigValue. Distinct from BlockHash (types.x), which is the
// hash of the SmallValue and serves as the block's identifier.
typedef SHA256Hash BigValueHash; // #[rust(newtype)]

// NAMING: "BigValue" and "SmallValue" are deliberate placeholders to defer
// the naming debate. The final names for this pair will be either
// Block/BlockHeader or ConsensusBasis/ConsensusValue.

// The big value: the canonical data on which consensus runs. Serialized and
// hashed to form the BigValueHash. Everything in the SmallValue is derived
// from this struct; the BigValue is authoritative.

// First fields of Bigvalue are from smallvalue; keep these in sync.
struct BigValue {
  // Reserved for future extensions.
  ExtensionPoint ext;
  BackendHeader backend;
  ValidatorID proposer;
  Upgrade upgrades<6>;

  // The hash of the previous block's SmallValue. Present here (rather than
  // only in SmallValue) so that the SmallValue is derivable from the BigValue
  // alone.
  BlockHash prev_small_value_hash;
  Nomination nomination;

};

typedef BigValue *OptBigValue;

// The small value: the block header. Serialized and hashed to form the
// BlockHash that identifies the block.
//
// Every field is derived from the BigValue; a SmallValue carries no
// information of its own. It exists so that consumers (light clients, repair,
// indexers) can identify and chain blocks, and verify transaction/event
// Merkle proofs, without holding the multi-kilobyte BigValue.
struct SmallValue {
  // Reserved for future extensions.
  ExtensionPoint ext;

  BackendHeader backend;
 
  ValidatorID proposer;
  Upgrade upgrades<6>;

  SmallValueHash previous_small_value_hash;
  
  BigValueHash big_value_hash;
};

} // namespace hogd
