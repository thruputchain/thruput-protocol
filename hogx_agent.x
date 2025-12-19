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

union HogxServiceStartResult switch (HogxOutcome outcome) {
  case HOGX_OK:
    ServiceState service_state;
  case HOGX_ERROR:
    string error<>;
};

union HogxServiceStopResult switch (HogxOutcome outcome) {
  case HOGX_OK:
    ServiceState service_state;
  case HOGX_ERROR:
    string error<>;
};

union HogxServiceQueryResult switch (HogxOutcome outcome) {
  case HOGX_OK:
    ServiceState service_state;
  case HOGX_ERROR:
    string error<>;
};

union HogxServiceListResult switch (HogxOutcome outcome) {
  case HOGX_OK:
    ServiceState service_state<>;
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

    HogxServiceStartResult hogxagent_service_start(ServiceDef) = 200;
    HogxServiceStopResult hogxagent_service_stop(ServiceID) = 210;
    HogxServiceQueryResult hogxagent_service_query(ServiceID) = 220;
    HogxServiceListResult hogxagent_service_list(void) = 230;

  }
  = 1;
}
= 0x20011004;

} // namespace hogx
