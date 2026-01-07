// clang-format off
namespace hogx {
// clang-format on

enum HogxOutcome {
  HOGX_OK = 0,
  HOGX_ERROR = 1,
};

union HogxHostConfigureResult switch (HogxOutcome outcome) {
case HOGX_OK:
  void;
case HOGX_ERROR:
  string error<>;
};

union HogxHostQueryResult switch (HogxOutcome outcome) {
case HOGX_OK:
  HostState host_state;
case HOGX_ERROR:
  string error<>;
};

union HogxUnitStartResult switch (HogxOutcome outcome) {
case HOGX_OK:
  void;
case HOGX_ERROR:
  string error<>;
};

union HogxUnitStopResult switch (HogxOutcome outcome) {
case HOGX_OK:
  void;
case HOGX_ERROR:
  string error<>;
};

union HogxUnitQueryResult switch (HogxOutcome outcome) {
case HOGX_OK:
  UnitState unit_state;
case HOGX_ERROR:
  string error<>;
};

union HogxUnitListResult switch (HogxOutcome outcome) {
case HOGX_OK:
  UnitState unit_state<>;
case HOGX_ERROR:
  string error<>;
};

union HogxUnitClearResult switch (HogxOutcome outcome) {
case HOGX_OK:
  void;
case HOGX_ERROR:
  string error<>;
};

program HogxAgent
{
  version HogxAgent1
  {

    void hogxagent_null(void) = 0;

    HogxHostConfigureResult hogxagent_host_configure(HostConfig) = 100;
    HogxHostQueryResult hogxagent_host_query(void) = 110;

    HogxUnitStartResult hogxagent_unit_start(UnitDef) = 200;
    HogxUnitStopResult hogxagent_unit_stop(UnitID) = 210;
    HogxUnitQueryResult hogxagent_unit_query(UnitID) = 220;
    HogxUnitListResult hogxagent_unit_list(void) = 230;
    HogxUnitClearResult hogxagent_unit_clear(SystemID) = 240;

  }
  = 1;
}
= 0x20011004;

} // namespace hogx
