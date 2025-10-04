// Copyright 2015 Stellar Development Foundation and contributors. Licensed
// under the Apache License, Version 2.0. See the COPYING file at the root
// of this distribution or at http://www.apache.org/licenses/LICENSE-2.0


%#include "types.hh"

namespace stellar {

%using hogd::SHA256Hash;
%using hogd::ExtensionPoint;

typedef unsigned int uint32;
typedef int int32;

typedef unsigned hyper uint64;
typedef hyper int64;

%using hogd::TimePoint;
typedef uint64 Duration;

typedef SHA256Hash ContractID;

} // namespace stellar
