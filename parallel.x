// clang-format off
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

/// A sequence of XDR-encoded items, cut into segments that can be encoded,
/// decoded and hashed in parallel.
///
/// `xdr` holds the segments back to back. Segment `i` is the XDR encoding of
/// `segment_tokens[i]` items, one after another, and takes the next
/// `segment_bytes[i]` bytes of `xdr`. The two arrays have the same length,
/// the number of segments, and `segment_bytes` adds up to the length of
/// `xdr`.
///
/// The hash that commits to a batch is
///
/// ```text
/// sha256(cxs(DomainSeparator("ParallelBatch")) ||
///        cxs(segment_tokens) || cxs(segment_bytes) ||
///        sha256(sha256(segment_0) || ... || sha256(segment_{n-1})))
/// ```
///
/// where `segment_i` is the bytes of segment `i`, and the `cxs` of each array
/// is its length followed by its elements. Only the segment hashes read
/// `xdr`, and they can be computed in parallel.
struct ParallelBatch {
  /// The number of items in each segment.
  unsigned int segment_tokens<>;
  /// The number of bytes of `xdr` in each segment.
  unsigned int segment_bytes<>;
  /// The segments, back to back.
  opaque xdr<>;
};

typedef ParallelBatch ParallelSignedTransactionBatch;  // #[rust(newtype)]
typedef ParallelBatch ParallelSignedTransactionHashBatch;  // #[rust(newtype)]
typedef ParallelBatch ParallelNondeterministicProposalDataBatch;  // #[rust(newtype)]

} // namespace hogd
