// clang-format off
%#include "types.hh"
%#include "validator.hh"

namespace bristlecone {
// clang-format on

typedef opaque BristleconeQuorumSetHash[32];

typedef unsigned int BristleconeCount;

// A slot number (aka height). Voting starts at slot 0. Slot -1 is the
// implicit genesis slot: it is never voted on, but slot 0 names it as its
// parent, so slots are signed.
typedef hyper BristleconeSlot;

typedef opaque BristleconeValue<>;
typedef BristleconeValue BristleconeValues<>;
typedef BristleconeValue *BristleconeOptValue;

// A leader proposal for the note's slot: the proposed value and the slot
// whose value it hash-chains onto.
struct BristleconeProposal {
  BristleconeSlot parent_slot;
  BristleconeValue value;
};

// The statement of a SAFE vote: the note's slot holds this value, with this
// parent slot.
struct BristleconeSafeStatement {
  BristleconeSlot parent_slot;
  BristleconeValue value;
};

// The statement of a TIMELY vote: whether the note's slot is timely.
struct BristleconeTimelyStatement {
  bool timely;
};

// The federated-voting phase of a vote: the sender votes for the statement,
// or accepts it.
enum BristleconeVoteType {
  BRISTLECONE_VOTE = 0,
  BRISTLECONE_ACCEPT = 1
};

struct BristleconeSafeVote {
  BristleconeSafeStatement statement;
  BristleconeVoteType vote;
};

struct BristleconeTimelyVote {
  BristleconeTimelyStatement statement;
  BristleconeVoteType vote;
};

// The three kinds of envelope: a proposal, a SAFE vote, and a TIMELY vote.
enum BristleconeContentType {
  BRISTLECONE_PROPOSAL = 0,
  BRISTLECONE_SAFE_VOTE = 1,
  BRISTLECONE_TIMELY_VOTE = 2
};

union BristleconeContent switch (BristleconeContentType content_type)
{
case BRISTLECONE_PROPOSAL:
  BristleconeProposal proposal;
case BRISTLECONE_SAFE_VOTE:
  BristleconeSafeVote safe_vote;
case BRISTLECONE_TIMELY_VOTE:
  BristleconeTimelyVote timely_vote;
};

// The signed payload of an envelope.
struct BristleconeNote {
  // The sending party.
  ValidatorID party;
  // The hash of the sender's quorum set (BristleconeQuorumSet).
  BristleconeQuorumSetHash qset_hash;
  // The slot the content applies to.
  BristleconeSlot slot;
  BristleconeContent content;
};

struct BristleconeEnvelope {
  BristleconeNote note;
  // The sending party's signature over the XDR encoding of the note.
  BristleconeSignature signature;
};

typedef BristleconeEnvelope BristleconeEnvelopes<>;

struct BristleconeQuorumSet {
  BristleconeCount threshold;
  ValidatorID parties<>;
  BristleconeQuorumSet inner_sets<>;
};

typedef BristleconeQuorumSet *BristleconeOptQuorumSet;

} // namespace bristlecone
