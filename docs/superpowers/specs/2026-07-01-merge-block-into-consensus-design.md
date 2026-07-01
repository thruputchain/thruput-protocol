# Merge block.x into consensus.x

**Date:** 2026-07-01
**Status:** Approved

## Problem

`consensus.x` and `block.x` were written separately and encode two overlapping
notions of a "block header": `ConsensusValue` (consensus.x) and `BlockHeader`
(block.x). Fields like `block_height` and `prev_block_hash` appear in both,
and `ConsensusValue` commits to `BlockHeader` indirectly via
`block_hash = sha256(BlockHeader)`.

Target model, following the standard blockchain header/body split:

- **`ConsensusValue`** is the *small* value — the block header.
  `sha256(ConsensusValue)` (a `ConsensusValueHash`) identifies the block.
- **`ConsensusBasis`** is the *big* data behind a value — a wrapper around
  `Nomination`. `sha256(ConsensusBasis)` is a `ConsensusBasisHash`.
- **`ConsensusValueWithBasis`** is the *big* value — a full block. Its XDR
  serialization begins with the XDR serialization of its `ConsensusValue`
  (fields repeated verbatim, prefix property stated as a documented
  invariant), followed by the `ConsensusBasis`.

`block.x` is deleted.

## Design

### consensus.x

```xdr
typedef opaque Upgrade<128>;

typedef SHA256Hash ConsensusValueHash; // #[rust(newtype)]
typedef SHA256Hash ConsensusBasisHash; // #[rust(newtype)]

// The small consensus value: the block header. Serialized and hashed to
// form the ConsensusValueHash that identifies the block.
struct ConsensusValue {
  unsigned hyper network_id;   // from BlockHeader
  BlockHeight block_height;
  TimePoint timestamp;
  ValidatorID proposer;
  Upgrade upgrades<6>;
  SHA256Hash txset_hash;       // from BlockHeader
  DbHash db_hash;              // from BlockHeader
  SHA256Hash events_hash;      // from BlockHeader
  ConsensusBasisHash basis_hash;
  ConsensusValueHash prev_value_hash;
};

// The big data behind a ConsensusValue; hashed to form ConsensusBasisHash.
struct ConsensusBasis {
  Nomination nomination;
};

typedef ConsensusBasis *OptConsensusBasis;

// The big consensus value: a full block.
// INVARIANT: the fields before [basis] are exactly the fields of
// ConsensusValue, in the same order, so that the XDR serialization of a
// ConsensusValueWithBasis begins with the XDR serialization of its
// ConsensusValue.
struct ConsensusValueWithBasis {
  unsigned hyper network_id;
  BlockHeight block_height;
  TimePoint timestamp;
  ValidatorID proposer;
  Upgrade upgrades<6>;
  SHA256Hash txset_hash;
  DbHash db_hash;
  SHA256Hash events_hash;
  ConsensusBasisHash basis_hash;
  ConsensusValueHash prev_value_hash;
  ConsensusBasis basis;
};
```

Decisions baked in:

- `basis_hash` survives (no circularity: `ConsensusBasis` does not contain
  `ConsensusValue`'s fields; only `ConsensusValueWithBasis` does).
- `prev_basis_hash` is **dropped**: `prev_value_hash` → previous
  `ConsensusValue` → its `basis_hash` already pins the previous basis.
- `block_hash` / `prev_block_hash` are **dropped** from `ConsensusValue`:
  `sha256(ConsensusValue)` is now the block identifier and `prev_value_hash`
  is the chain link.
- All "basis" names (`ConsensusBasisHash`, `basis_hash`, `OptConsensusBasis`,
  `repair_missing_basis`) are kept to avoid rename churn; `ConsensusBasis`
  slims to a wrapper around `Nomination`.
- The prefix property is expressed by repeating the fields plus a documented
  invariant (not by embedding `ConsensusValue` as a field).

### block.x

Deleted. `BlockHeader` is gone; its fields live in `ConsensusValue`. The
`BlockHash` typedef stays in `types.x` (still used by `nomination.x`, which
has its own pending XXX renames).

### Consumers

- **repair.x** — unchanged. `repair_missing_basis(ConsensusValue) ->
  OptConsensusBasis`: caller already holds the CV, only the big tail is
  missing.
- **catchup.x** — `CatchupBlock.consensus_basis` becomes
  `ConsensusValueWithBasis consensus_value_with_basis` (a slim basis no
  longer carries the header metadata catchup needs).
- **multiplex.x** — the `MultiplexMessageConsensusBasis` arm becomes
  `ConsensusValueWithBasis consensus_value_with_basis` (the proposer knows
  execution results before broadcasting). Enum member name kept.
- **hogd/xdr/CMakeLists.txt** (../hogd repo) — drop the `block.x` entry.

### Out of scope (follow-up work)

- The 4 C++ `BlockHeader` call sites in `hogd/hogd`
  (`mempool/rpc_from_coord.cc`, `mempool/shared.h`,
  `mempool/test/mempool_test.cc`, `hogdb/rpc_from_sched.cc`). Block-hash
  semantics change (`sha256(BlockHeader)` → `sha256(ConsensusValue)`), so
  these need timestamp/proposer/upgrades/prev_value_hash threaded in.
- `Nomination`'s duplicated `block_height` / `block_hash` /
  `prev_block_hash` fields and its XXX renames.

### Semantic note

With `ConsensusBasis` slimmed, `basis_hash` attests only to the nomination.
Proposal metadata (timestamp, proposer, upgrades) is attested by
`sha256(ConsensusValue)` instead. Anything verifying a fetched basis checks
`sha256(basis) == cv.basis_hash` and trusts the metadata via the CV it
already holds.
