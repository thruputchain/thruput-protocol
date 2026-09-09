namespace hogd {

/// Bytes one incremental SHA-256 buffer may absorb when a configuration does
/// not state `kConfigParamMaxSHA256BufferBytes`. Consensus-critical, so
/// frozen: every chain predating the parameter ran under it.
const kSHA256BufferMaxSize = 4096;

/// Storage savepoints one transaction may hold when a configuration does not
/// state `kConfigParamMaxSavepointDepth`. Frozen for the same reason.
const kMaxSavepointDepth = 1024;

/// Bytes of RV32 code an attached artifact may carry when a configuration
/// does not state `kConfigParamMaxRv32CodeBytes`. Frozen for the same reason.
const kDefaultMaxRv32CodeBytes = 65536;

/// Bytes of RV32 guest memory an attached artifact may declare when a
/// configuration does not state `kConfigParamMaxRv32MemoryBytes`. Frozen for
/// the same reason.
const kDefaultMaxRv32MemoryBytes = 65536;

} // namespace hogd
