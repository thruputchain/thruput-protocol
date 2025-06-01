namespace hogd {

enum ResultType {
  Ok = 0,
  Err = 1,
};

union Result<T, E> switch (ResultType is_err) {
case Ok:
  T val;
case Err:
  E err;
};

enum ContractErrorType {
    // "Storage-layer error"
    StorageErr = 0,

    // "System error"
    SystemErr = 1,
};

union ContractError switch (ContractErrorType err_type) {
case StorageErr:
    void;
case SystemErr:
    void;
};

enum ErrorType {
    // Contract already initialized
    AlreadyInitialized = 0,

    // Caller must be contract owner
    MustBeContractOwner = 1,

    // Internal contract error
    ContractErr = 2,
};

union Error switch (ErrorType err_type) {
case AlreadyInitialized:
    void;
case MustBeContractOwner:
    void;
case ContractErr:
    ContractError contract_error;
};

} // namespace hogd
