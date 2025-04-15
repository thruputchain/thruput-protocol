namespace hogd {

// unique id that determines the randomness
// in creating a channel's multicast tree
typedef opaque BroadcastChannelID[32];

typedef unsigned int SeqNo;

typedef SHA256Hash MulticastTreeHash;
typedef SHA256Hash BroadcastMessageHash;

struct MulticastTreeNode {
  ValidatorPublicInfo node;
  MulticastTreeHash children<>;
};

typedef MulticastTreeNode MulticastTreeNodes<>;

// BroadcastChannel is a fixed-width structure, so it can be used conveniently
// as a key in golang maps.
struct BroadcastChannel {
  ValidatorID source_id;
  BroadcastChannelID channel_id;
  MulticastTreeHash tree_hash;
};

struct BroadcastHeader {
  ValidatorPublicInfo source;
  // The source validator signs the channel to bind together its own identity
  // with the tree hash. This prevents malicious non-source nodes from changing
  // the tree.
  Signature source_signature;
  BroadcastChannel channel;
  SeqNo seqno;
  // prev_msg is the hash of the previous BroadcastMessage, or nil if this is
  // the first message.
  BroadcastMessageHash *prev_msg;
};

struct BroadcastMessage {
  BroadcastHeader header;
  opaque payload<>;
};

struct Delivery {
  // relayer is the identity of the node that made this call to
  // `broadcast_deliver`
  ValidatorPublicInfo relayer;
  BroadcastMessage msg;
  // Senders may optimistically choose to describe the entire multicast tree in
  // the first message, in order to reduce the number of attempts (via
  // `broadcast_expand` rpc) by downstream nodes to recover the multicast tree.
  MulticastTreeNodes *tree_nodes;
};

struct ReconcileMessages {
  BroadcastHeader missing_msgs<>;
};

struct ReconciledMessages {
  BroadcastMessage msgs<>;
};

program Broadcast {
  version Broadcast1 {

    void broadcast_null(void) = 0;

    void broadcast_deliver(Delivery) = 10;

    // broadcast_reconcile requests a set of messages described by their
    // headers.
    //
    // responses to broadcast_reconcile are cached along the multicast tree for
    // the lifetime of the channel.
    ReconciledMessages broadcast_reconcile(ReconcileMessages) = 20;

    // broadcast_expand requests a reconstruction of the entire multicast tree,
    // given its hash.
    //
    // responses to broadcast_expand are cached along the
    // multicast tree for the lifetime of the channel.
    MulticastTreeNodes broadcast_expand(MulticastTreeHash) = 30;
  }
  = 1;
}
= 0x8aa81111;

} // namespace hogd
