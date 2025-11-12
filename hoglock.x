// clang-format off
namespace hogd {
// clang-format on

typedef string LockObject<>;
typedef LockObject LockObjects<>;

typedef string LockLease<>;

// Lock service for the hog cluster
program HogLock
{
  version HogLock1
  {

    void hoglock_null(void) = 0;

    LockLease hoglock_lock(LockObjects) = 1;

    void hoglock_renew(LockLease) = 2;

    bool hoglock_check(LockLease) = 3;

  }
  = 1;
}
= 0x22113443;

} // namespace hogd
