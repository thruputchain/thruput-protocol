// clang-format off

%#include "network.hh"
%#include "rpc_types.hh"
%#include "storage_item.hh"
%#include "types.hh"

namespace hogd
{
// clang-format on

/// Input: a batch of items to read, identified by (address, key).
typedef AddressAndKey AddressAndKeyBatch<>;

/// Per-item result for DbGateway1::dbgateway_get_items.
///
/// The success case carries the WireStorageItem; kRPCNotFound is the
/// legitimate outcome for an item that does not exist in the committed
/// snapshot (e.g., a balance item for an address that has never received
/// hogs); other errors indicate server-side failures.  Defined locally
/// rather than reusing `ExpectedStorageItem` from executor_to_db_rpc so
/// this program has no cross-dependency on the executor-side RPC.
union DbGatewayItemResult switch (RPCError error)
{
case kRPCNone:
  WireStorageItem item;
default:
  void;
};

typedef DbGatewayItemResult DbGatewayItemBatch<>;

/// Batch-read payload: one BlockHeight applies to every result in the
/// batch because all reads come from a single committed snapshot.
struct DbGatewayPayload {
  BlockHeight block_height;
  DbGatewayItemBatch items;
};

/// Outer result: the RPC itself succeeded or failed as a whole.
/// Per-item misses live inside the `items` batch as kRPCNotFound.
union DbGatewayResult switch (RPCError error)
{
case kRPCNone:
  DbGatewayPayload payload;
default:
  void;
};

enum DbGatewayIntroOutcome {
  DbGatewayIntroSuccess = 0,
  DbGatewayIntroMismatchedProtocol = 1
};

// API exposed from the Db (hog_db) for the public RPC Gateway.
//
// Reads are always against the latest committed snapshot at the time
// the RPC is served; no BlockID argument is accepted in v1.  A future
// method variant can add historical reads without breaking this shape.
//
// Batch is the only read form exposed; callers that want a single
// item pass a one-element batch.  The gateway aggregates concurrent
// reads into batches itself, so a singular form would be redundant.
program DbGateway
{
  version DbGateway1
  {
    DbGatewayIntroOutcome dbgateway_intro(ProtocolCommit) = 0;
    DbGatewayResult dbgateway_get_items(AddressAndKeyBatch) = 1;
  } = 1;
}
= 0x44424757;

} // namespace hogd
