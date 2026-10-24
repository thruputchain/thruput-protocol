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
/// implementation detail and may change between versions; the first
/// byte is a format-version tag so stale cursors fail cleanly rather
/// than being silently misinterpreted.
///
/// The bound must stay in sync with `hogd::cursor::kMaxCursorBytes`.
/// It is the server's own cursor-format cap: encoded cursors are far
/// smaller, and a client only ever echoes back a cursor the server
/// authored.  Declaring it here rejects an oversized cursor during XDR
/// deserialization, before an owning buffer is materialized, rather
/// than after the fact in `cursor::decode`.
typedef opaque PaginationCursor<256>;

} // namespace hogd
