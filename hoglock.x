// clang-format off
namespace hogd {
// clang-format on

typedef string HogXID<>;

typedef string HogHost<>;
typedef HogHost HogHosts<>;

typedef string HogNamespace<>;
typedef HogNamespace HogNamespaces<>;

struct HogAsk {
  HogHosts fixed;
  HogHosts variable;
};

// Lock service for the hog cluster
program HogLock
{
  version HogLock1
  {

    void hoglock_null(void) = 0;

    HogHosts hoglock_lock(HogXID, HogAsk) = 1;
    void hoglock_renew(HogXID) = 2;
    bool hoglock_check(HogXID) = 3;

    void hoglock_signal(HogXID, HogNamespaces) = 4;
    void hoglock_wait(HogXID, HogNamespaces) = 5;

  }
  = 1;
}
= 0x22113443;

} // namespace hogd
