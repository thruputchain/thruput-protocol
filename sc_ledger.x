// Adapted from:
// https://github.com/stellar/stellar-xdr/blob/3d7e7002c29ba038ce0a9f67130d732ccb028768/Stellar-ledger.x

// Retained from original:
//// Copyright 2015 Stellar Development Foundation and contributors. Licensed
//// under the Apache License, Version 2.0. See the COPYING file at the root
//// of this distribution or at http://www.apache.org/licenses/LICENSE-2.0

namespace hogd {

enum ContractEventType { SYSTEM = 0, CONTRACT = 1, DIAGNOSTIC = 2 };

struct ContractEvent {
  ExtensionPoint ext;

  ContractID *contractID;
  ContractEventType type;

  union switch (int v)
  {
  case 0:
    struct {
      SCVal topics<>;
      SCVal data;
    } v0;
  }
  body;
};

} // namespace hogd
