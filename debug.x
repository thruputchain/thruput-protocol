// clang-format off
namespace hogd {
// clang-format on

// The debug service helps nodes in an experiment coordinate when everyone is up.
program Debug
{
  version Debug1
  {

    void debug_ready(void) = 0;

  }
  = 1;
}
= 0xbbeebbee;

} // namespace hogd
