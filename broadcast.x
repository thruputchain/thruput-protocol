namespace hogd {

typedef opaque MulticastTreeID[32]; // unique id that determines the randomness
                                    // in creating the tree
typedef SHA256Hash MulticastTreeHash;
typedef SHA256Hash MulticastMsgHash;

struct MulticastTreeNode {
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
  MulticastStripe stripe;
  MulticastMsg msg;
};

struct ExpandMulticastTreeResult {
  MulticastTreeNode tree_nodes<>;
};

program Broadcast {
  version Broadcast1 {

    void broadcast_null(void) = 0;

    void broadcast_deliver(DeliverArg) = 10;

    ExpandMulticastTreeResult broadcast_expand_multicast_tree(
        MulticastTreeHash) = 20;
  }
  = 1;
}
= 0x8aa81111;

} // namespace hogd
