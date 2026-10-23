// clang-format off

%#include "network.hh"
%#include "network_config.hh"
%#include "rpc_types.hh"
%#include "storage_cost.hh"
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
/// native tokens); other errors indicate server-side failures.  Defined locally
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

/// Network-supplied execution and storage rules read at one committed tip.
/// `tip.network_config` preserves the parameters explicitly stated by the chain.
/// `effective_config` states every parameter understood by the serving runtime,
/// resolving omitted values through the same rules used by execution. It is a
/// resolved reading, not a replacement for the hashed network configuration.
/// The rules apply to execution following `tip`; they are not a promise about
/// the block in which a subsequently submitted transaction will be included.
/// Storage prices are integer native-token base units (10^7 per token).
struct DbGatewayConfig {
  DbTip tip;
  NetworkConfig effective_config;
  StorageCostModelXdr storage_cost_model;
};

/// No committed tip: kRPCNotFound. Unreadable rules: kRPCUnrecoverable.
/// A missing reading must never be represented as zero prices or empty rules.
union DbGatewayConfigResult switch (RPCError error)
{
case kRPCNone:
  DbGatewayConfig config;
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
    DbGatewayConfigResult dbgateway_get_config(void) = 2;
  } = 1;
}
= 0x44424757;

} // namespace hogd
