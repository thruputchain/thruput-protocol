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

union HogxUnitTailResult switch (HogxOutcome outcome) {
case HOGX_OK:
  void;
case HOGX_ERROR:
  string error<>;
};

struct HogxTailKick {
  string tail_id<>;
  UnitID unit_id;
  SocketAddress delivery_address;
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
    HogxUnitClearResult hogxagent_unit_clear(UnitID) = 240;

    HogxUnitTailResult hogxagent_unit_tail(HogxTailKick) = 300;

  }
  = 1;
}
= 0x20011004;

struct HogxTailChunk {
  string tail_id<>;
  UnitID unit_id;
  unsigned hyper index;
  opaque chunk<>;
};

program HogxTail
{
  version HogxTail1
  {

    void hogxtail_null(void) = 0;

    bool hogxtail_deliver(HogxTailChunk) = 100;

  }
  = 1;
}
= 0x20015004;

} // namespace hogx
