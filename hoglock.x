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
  hyper variable;
};

struct HogHeld {
  HogHost host;
  HogXID xid;
  hyper demand;
  hyper *acquired;
};
typedef HogHeld HogHelds<>;

enum HogOutcome {
  HogOK = 0,
  HogError = 1,
};

union HogLockResult switch (HogOutcome outcome) {
case HogOK:
  HogHosts ok;
case HogError:
  string msg<>;
default:
  void;
};

union HogResult switch (HogOutcome outcome) {
case HogOK:
  void;
case HogError:
  string msg<>;
default:
  void;
};

// Lock service for the hog cluster
program HogLock
{
  version HogLock1
  {

    void hoglock_null(void) = 0;

    HogLockResult hoglock_lock(HogXID, HogAsk) = 1;
    HogResult hoglock_unlock(HogXID, HogHost) = 2;

    void hoglock_renew(HogXID) = 3;
    bool hoglock_check(HogXID) = 4;

    HogResult hoglock_signal(HogXID, HogNamespaces) = 5;
    HogResult hoglock_wait(HogXID, HogNamespaces) = 6;

    HogHelds hoglock_list(void) = 7;

  }
  = 1;
}
= 0x22113443;

} // namespace hogd
