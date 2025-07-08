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

typedef DogwoodInt64 DogwoodStreamID;
typedef DogwoodInt64 DogwoodTransmissionID;

struct DogwoodStream {
  DogwoodStreamID stream_id;
  DogwoodTreeHash *route_hash;
  DogwoodTreeNodes *route_nodes;
};

struct DogwoodTransmission {
  DogwoodTransmissionID transmission_id;
  DogwoodInt64 num_payload_bytes;
  DogwoodInt32 num_payload_sheaves;
  DogwoodInt32 num_parity_sheaves;
  DogwoodInt32 num_chunks_per_sheaf;
  DogwoodInt32 seed; // seed used to shuffle sheafs for cross-sheaf coding
};

struct DogwoodChunk {
  DogwoodInt32 sheaf_index;
  DogwoodInt32 chunk_index;
  opaque chunk<>;
};

struct DogwoodPackage {
  DogwoodTransmission transmission;
  DogwoodChunk chunk;
};

// messages

struct DogwoodDelivery {
  DogwoodStream stream;
  DogwoodPackage pkg;
};

// signed messages

struct DogwoodDeliveryEnvelope {
  Signature signature;
  DogwoodDelivery delivery;
};

program Dogwood
{
  version Dogwood1
  {

    void dogwood_null(void) = 0;

    void dogwood_deliver(DogwoodDeliveryEnvelope) = 10;
  }
  = 1;
}
= 0x8ee82002;

} // namespace hogd
