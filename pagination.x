// clang-format off

%#include "types.hh"

namespace hogd
{
// clang-format on

/// Direction to walk a paginated stream.
enum IterationOrder {
  IterationOrderAscending = 0,
  IterationOrderDescending = 1
};

/// Where to begin iteration on the initial call.  Independent of
/// `IterationOrder`; combinations that run off the end of the range
/// (AnchorAtEnd with IterationOrderAscending, AnchorAtBeginning with
/// IterationOrderDescending) return empty, because there is nothing
/// past that end to iterate toward.
enum BlockAnchorKind {
  AnchorAtBeginning = 0,   // oldest block the indexer still retains
  AnchorAtEnd = 1,         // highest block the indexer has processed
  AnchorAtHeight = 2       // caller-specified
};

union BlockAnchor switch (BlockAnchorKind kind) {
case AnchorAtBeginning:
case AnchorAtEnd:
  void;
case AnchorAtHeight:
  BlockHeight height;
};

/// Opaque pagination cursor authored by the server.  Clients pass
/// back whatever they received in the previous response's `cursor`
/// field to continue pagination.  The encoding is a server-side
/// implementation detail and may change between versions; it begins
/// with a server-defined version word so stale cursors fail cleanly
/// rather than being silently misinterpreted.
typedef opaque PaginationCursor<>;

} // namespace hogd
