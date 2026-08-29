namespace hogd {

// Definitions for network config parameters

/// ServerAddress is an IP (or hostname) and port address, separated by a
/// colon.
typedef string ServerAddress<>;

/// UPID is a globally unique process identifier (function of start time, place
/// and randomness)
typedef opaque UPID[8];

/// ProtocolCommit describes a specific protocol repo version.
/// Used to ensure communicating daemons in a validator deployment are compatible.
///
/// Printable ASCII: a short prefix followed by the leading characters of the
/// protocol repo commit id. Peers only ever compare it byte for byte, and it
/// travels as plain text outside XDR too -- runtime manifests, log lines, and
/// indexer outbox filenames -- so it stays text rather than a raw hash.
///
/// Fixed width, so a peer cannot declare a length: decoding reads exactly
/// these bytes into an inline array, with no length prefix and no allocation.
/// 20 is a whole number of XDR words, so nothing is spent on padding.
typedef opaque ProtocolCommit[20];

} // namespace hogd
