// clang-format off
namespace hogd {
// clang-format on

// The advisory service, used during development,
// helps nodes in an experiment coordinate when everyone is up.
program Advisory
{
  version Advisory1
  {

    void advisory_ready(void) = 0;

  }
  = 1;
}
= 0xbbeebbee;

} // namespace hogd
