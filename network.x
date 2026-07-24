
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
typedef string ProtocolCommit<>;

} // namespace hogd
