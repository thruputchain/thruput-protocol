namespace hogd {

typedef opaque SoloNodeID[32];

typedef unsigned hyper SoloSlotIndex;

typedef opaque SoloPayload<>;

struct SoloValue {
  SoloPayload payloads<>;
};

enum SoloValidationLevel {
  SoloInvalidValue = 0,
  SoloMaybeValidValue = 1,
  SoloFullyValidValue = 2,
};

struct SoloNomination {
  SoloSlotIndex slot_index;
  SoloValue value;
};

struct SoloSignedNomination {
  ValidatorPublicInfo signer;
  Signature signature;
  SoloNomination nomination;
};

struct SoloValidate {
  SoloSlotIndex slot_index;
  SoloValue value;
};

struct SoloSignedValidate {
  ValidatorPublicInfo signer;
  Signature signature;
  SoloValidate validate;
};

struct SoloExternalized {
  SoloSlotIndex slot_index;
  SoloValue value;
};

struct SoloSignedExternalized {
  ValidatorPublicInfo signer;
  Signature signature;
  SoloExternalized externalized;
};

// SoloServer is the server component of the centralized SCP implementation.
program SoloServer {
  version SoloServer1 {

    void soloserver_null(void) = 0;

    void soloserver_nominate(SoloSignedNomination) = 10;
  }
  = 1;
}
= 0x8aa81222;

// SoloClient is the client component of the centralized SCP implementation.
program SoloClient {
  version SoloClient1 {

    void soloclient_null(void) = 0;

    SoloValidationLevel soloclient_validate(SoloSignedValidate) = 10;

    void soloclient_externalized(SoloSignedExternalized) = 20;
  }
  = 1;
}
= 0x8aa81223;

} // namespace hogd
