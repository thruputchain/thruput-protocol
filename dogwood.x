namespace hogd {

// trees

typedef SHA256Hash DogwoodTreeHash;
typedef hyper DogwoodInt64;
typedef int DogwoodInt32;

struct DogwoodTreeNode {
  ValidatorID node;
  DogwoodTreeHash children<>;
};

typedef DogwoodTreeNode DogwoodTreeNodes<>;

// protocol

struct DogwoodRoute {
  DogwoodTreeNodes trees<>;
};

struct DogwoodTransmission {
  DogwoodInt64 num_payload_bytes;
  DogwoodInt32 num_payload_sheaves;
  DogwoodInt32 num_parity_sheaves;
  DogwoodInt32 num_chunks_per_sheaf;
  DogwoodInt32 seed; // seed used to shuffle sheafs for cross-sheaf coding
};

struct DogwoodHeader {
  DogwoodInt32 sheaf_index;
  DogwoodInt32 chunk_index;
};

struct DogwoodDelivery {
  DogwoodTreeHash route;
  DogwoodTransmission transmission;
  DogwoodHeader header;
  opaque chunk<>;
};

struct DogwoodRouteEnvelope {
  Signature signature;
  DogwoodRoute route;
};

struct DogwoodDeliveryEnvelope {
  Signature signature;
  DogwoodDelivery delivery;
};

program Dogwood
{
  version Dogwood1
  {

    void dogwood_null(void) = 0;

    void dogwood_route(DogwoodRouteEnvelope) = 10;

    void dogwood_deliver(DogwoodDeliveryEnvelope) = 20;
  }
  = 1;
}
= 0x8ee82002;

} // namespace hogd
