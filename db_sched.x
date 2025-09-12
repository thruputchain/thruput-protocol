// clang-format off
%#include "account.hh"
%#include "rpc_types.hh"
%#include "types.hh"

namespace hogd {
  // clang-format on

  enum DbSchedResult {
    DbSchedResultOK = 0,
    DbSchedResultError = 1,
  };

  const kHogAgeGroupToSchedule = 0;
  const kHogAgeGroupAlreadyScheduled = 1;
  const kHogAgeGroupReceived = 2;
  const kHogAgeNumGroups = 3;

  struct HogAge {
    ContractAddress address;
    uint128_xdr num_hogs[kHogAgeNumGroups];
    BlockHeight average_ages[kHogAgeNumGroups];
  };

  typedef HogAge HogAgeBatch<>;

  union HogAgeResult switch (DbSchedResult result)
  {
  case DbSchedResultOK:
    HogAgeBatch hog_age_batch;
  default:
    void;
  };

  union DbAccountAuthDataBatchResult switch (DbSchedResult result)
  {
  case DbSchedResultOK:
    AccountAuthData account_auth_data_batch<>;
  default:
    void;
  };

  program DbSched
  {
    version DbSched1
    {
      void dbsched_null(void) = 0;

      DbAccountAuthDataBatchResult dbsched_get_account_auth_data(
          BlockID, ContractAddressBatch) = 10;

      HogAgeResult dbsched_get_hog_ages(ContractAddressBatch) = 20;
      DbSchedResult dbsched_write_hog_ages(HogAgeBatch) = 30;
    }
    = 1;
  }
  = 0x88887ee7;

} // namespace hogd
