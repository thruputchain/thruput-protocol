
namespace hogd {

// Definitions for network config parameters

/// ServerAddress is an IP (or hostname) and port address, separated by a
/// colon.
typedef string ServerAddress<>;

/// UPID is a globally unique process identifier (function of start time, place
/// and randomness)
typedef opaque UPID[8];

/// Protocol describes a specific protocol and version.
typedef string Protocol<>;

} // namespace hogd
