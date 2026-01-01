// clang-format off
%#include "transaction.hh"
%#include "types.hh"

namespace hogd {
// clang-format on

// XXX: speed of decoding index?

struct ParallelSignedTransactions {
	int index<>;
	opaque xdr<>;
};

struct ParallelSignedTransactionHashes {
	int index<>;
	opaque xdr<>;
};

struct ParallelNondeterministicProposalDatas {
	int index<>;
	opaque xdr<>;
};

} // namespace hogd
