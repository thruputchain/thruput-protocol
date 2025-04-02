namespace hogd {

typedef opaque MulticastTreeID[32]; // unique id that determines the randomness
                                    // in creating the tree
typedef SHA256Hash MulticastTreeHash;
typedef SHA256Hash MulticastMsgHash;

struct MulticastTreeNode {
  ValidatorPublicInfo node;
  MulticastTreeHash children<>;
};

struct MulticastStripe {
  ValidatorID source_validator_id;
  MulticastTreeID tree_id;
  MulticastTreeHash tree_hash;
  // sender may optimistically describe the tree in the first message
  MulticastTreeNode *tree_root;
};

struct MulticastMsg {
  unsigned int seq_no;
  opaque payload<>;
  MulticastMsgHash *prev_hash; // XXX: hash the stripe data as a first msg?
};

struct DeliverArg {
  ValidatorPublicInfo relayer; // the node that made this call
  MulticastStripe stripe;
  MulticastMsg msg;
};

struct ReconcileArg {
  int xxx;
};

struct ReconcileResult {
  int xxx;
};

struct ExpandMulticastTreeResult {
  MulticastTreeNode tree_nodes<>;
};

program Broadcast {
  version Broadcast1 {

    void broadcast_null(void) = 0;

    void broadcast_deliver(DeliverArg) = 10;

    // broadcast_reconcile is a reverse-multicast call, i.e.
    // it should be called by a child to a parent in the multicast tree.
    // responses to broadcast_reconcile may be cached along the multicast tree.
    ReconcileResult broadcast_reconcile(ReconcileArg) = 20;

    // broadcast_expand_multicast_tree is a reverse-multicast call, i.e.
    // it should be called by a child to a parent in the multicast tree.
    // responses to broadcast_expand_multicast_tree may be cached along the
    // multicast tree.
    ExpandMulticastTreeResult broadcast_expand_multicast_tree(
        MulticastTreeHash) = 30;
  }
  = 1;
}
= 0x8aa81111;

} // namespace hogd
