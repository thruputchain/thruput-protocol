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

union Res<T> switch (ResultType is_err) {
case Ok:
  T val;
case Err:
  Error err;
};

struct Void {
    // temporary: ReadXdr/WriteXdr derive-macros don't support unnamed fields
    int not_void;
};

typedef uint128_xdr Amount;
typedef int128_xdr Difference;

program ERC20 {
    version v0_1_0 {
        // Initialize contract with address of the administrative
        // owner, who can mint and burn
        Res<Void> initialize(
            /* contract_owner */ ContractAddress
        ) = 4;

        // Transfer from caller to `receiver` address
        Res<Void> transfer(
            /* receiver */ ContractAddress,
            /* amount */ Amount
        ) = 7;

        // Transfer from `owner` to `receiver` address, using allowance
        Res<Void> transfer_from(
            /* owner */ ContractAddress,
            /* receiver */ ContractAddress,
            /* amount */ Amount
        ) = 8;

        // Adjust allowance for `spender` by `amount` (positive or negative)
        Res<Void> adjust_allowance(
            /* spender */ ContractAddress,
            /* amount */ Difference
        ) = 0;

        // Get balance for given address
        Res<Amount> get_balance_of(
            /* addr */ ContractAddress
        ) = 3;

        // Get balance for caller
        Res<Amount> get_balance(void) = 2;

        // Create tokens into `receiver` address
        Res<Void> mint(
            /* receiver */ ContractAddress,
            /* amount */ Amount
        ) = 5;

        // Destroy tokens from `owner` address
        Res<Void> burn(
            /* owner */ ContractAddress,
            /* amount */ Amount
        ) = 1;

        // Get total supply of outstanding tokens
        Res<Amount> total_supply(void) = 6;

   } = 10;
} = 0;

} // namespace hogd
