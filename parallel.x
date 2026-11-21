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
/// `sha256(cxs(DomainSeparator("ParallelBatch")) || cxs(BatchCommit))`, of the
/// [`BatchCommit`] made from the batch.
struct ParallelBatch {
  /// The number of items in each segment.
  unsigned int segment_tokens<>;
  /// The number of bytes of `xdr` in each segment.
  unsigned int segment_bytes<>;
  /// The segments, back to back.
  opaque xdr<>;
};

/// The preimage of the hash that commits to a [`ParallelBatch`]. As for the
/// other hashes that use a `DomainSeparator` (see preimage.x), the separator
/// comes before it:
///
/// ```text
/// sha256(cxs(DomainSeparator("ParallelBatch")) || cxs(BatchCommit))
/// ```
///
/// `DomainSeparator("ParallelBatch")` has an `ext` of 0 and the bytes of the
/// name as its `domain_separator`. That `ext` belongs to the separator, which
/// every use of the type shares, and is not the version of this hash: the
/// `ext` of this struct is.
///
/// The struct holds the batch's two count arrays and, in place of the batch's
/// bytes, the hash of each segment. Only the segment hashes read the bytes,
/// and they can be computed in parallel. The three arrays have the same
/// length, the number of segments.
///
/// Does not travel on network: a node makes it from a batch to hash it.
struct BatchCommit {
  /// The version of this preimage, whose only value today is 0. A revision
  /// that changes what the hash of a batch commits to gives it a new value.
  ExtensionPoint ext;
  /// The batch's `segment_tokens`.
  unsigned int segment_tokens<>;
  /// The batch's `segment_bytes`.
  unsigned int segment_bytes<>;
  /// `segment_hashes[i]` is the SHA-256 of the bytes of segment `i`: the
  /// `segment_bytes[i]` bytes of the batch's `xdr` that follow the segments
  /// before it.
  SHA256Hash segment_hashes<>;
};

typedef ParallelBatch ParallelSignedTransactionBatch;  // #[rust(newtype)]
typedef ParallelBatch ParallelSignedTransactionHashBatch;  // #[rust(newtype)]
typedef ParallelBatch ParallelNondeterministicProposalDataBatch;  // #[rust(newtype)]

} // namespace hogd
