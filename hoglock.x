// clang-format off
namespace hogd {
// clang-format on

typedef string LockObject<>;
typedef LockObject LockObjects<>;

typedef string LockLease<>;

typedef string HogChan<>;
typedef string HogMsg<>;

// Lock service for the hog cluster
program HogLock
{
  version HogLock1
  {

    void hoglock_null(void) = 0;

    LockLease hoglock_lock(LockObjects) = 1;
    void hoglock_renew(LockLease) = 2;
    bool hoglock_check(LockLease) = 3;

    void hoglock_signal(HogChan, HogMsg) = 4;
    void hoglock_wait(HogChan, HogMsg) = 5;

  }
  = 1;
}
= 0x22113443;

} // namespace hogd
