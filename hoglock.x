// clang-format off
namespace hogd {
// clang-format on

typedef string LockObject<>;
typedef LockObject LockObjects<>;

typedef string LockHandle<>;

// Lock service for the hog cluster
program HogLock
{
  version HogLock1
  {

    void hoglock_null(void) = 0;

    LockHandle hoglock_lock(LockObjects) = 1;

    void hoglock_refresh(LockHandle) = 2;

    bool hoglock_check(LockHandle) = 3;

  }
  = 1;
}
= 0x22113443;

} // namespace hogd
