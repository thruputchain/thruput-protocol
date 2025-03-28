namespace hogd {

// BlockHeight is the height of a block.
typedef unsigned int BlockHeight;

// ServerAddress is an IP (or hostname) and port address, separated by a colon.
typedef string ServerAddress<>;

// UPID is a globally unique process identifier (function of start time, place
// and randomness)
typedef opaque UPID[8];

// Protocol describes a specific protocol and version.
typedef string Protocol<>;

// CoordinatorCard uniquely describes a coordinator instance.
struct CoordinatorCard {

  Protocol protocol;

  UPID upid;
};

// ExecutorCard uniquely describes an executor instance.
struct ExecutorCard {

  Protocol protocol;

  UPID upid;

  ServerAddress address;
};

// DbCard uniquely describes a database shard instance and its initial state.
struct DbCard {

  Protocol protocol;

  UPID upid;

  BlockHeight block_height;

  unsigned int shard_count;

  ServerAddress address;

  // TODO: KeyPrefixes describes the key prefixes handled by this shard
  // KeyPrefixes key_prefixes;
};

struct IntroDbResult {
  // cc holds the identity of the coordinator that responded
  CoordinatorCard cc;
};

struct IntroExecutorResult {
  // cc holds the identity of the coordinator that responded
  CoordinatorCard cc;
};

struct ListDbResult {
  // cc holds the identity of the coordinator that responded
  CoordinatorCard cc;

  // is_ready indicates whether the db cluster is ready to use
  bool is_ready;

  // shards describes all currently available db shards
  DbCard shards<>;
};

program Coordinator {
  version Coordinator1 {

    void coordinator_null(void) = 0;

    // intro_db is called by db shards to introduce themselves to the
    // coordinator.
    IntroDbResult coordinator_intro_db(DbCard) = 1;

    // intro_executor is called by executors to introduce themselves to the
    // coordinator.
    IntroExecutorResult coordinator_intro_executor(ExecutorCard) = 2;

    // list_db is called by executors to learn the available set of db shards
    // and whether the db system is ready to use.
    ListDbResult coordinator_list_db(void) = 3;
  }
  = 1;
}
= 0x3eef0101;

} // namespace hogd
