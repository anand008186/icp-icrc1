type BlockIndex = nat;
type Subaccount = blob;
// Number of nanoseconds since the UNIX epoch in UTC timezone.
type Timestamp = nat64;
// Number of nanoseconds between two [Timestamp]s.
type Duration = nat64;
type Tokens = nat;
type TxIndex = nat;
type Allowance = record { allowance : nat; expires_at : opt nat64 };
type AllowanceArgs = record { account : Account; spender : Account };
type Approve = record {
  fee : opt nat;
  from : Account;
  memo : opt vec nat8;
  created_at_time : opt nat64;
  amount : nat;
  expected_allowance : opt nat;
  expires_at : opt nat64;
  spender : Account;
};
type ApproveArgs = record {
  fee : opt nat;
  memo : opt vec nat8;
  from_subaccount : opt vec nat8;
  created_at_time : opt nat64;
  amount : nat;
  expected_allowance : opt nat;
  expires_at : opt nat64;
  spender : Account;
};
type ApproveError = variant {
  GenericError : record { message : text; error_code : nat };
  TemporarilyUnavailable;
  Duplicate : record { duplicate_of : nat };
  BadFee : record { expected_fee : nat };
  AllowanceChanged : record { current_allowance : nat };
  CreatedInFuture : record { ledger_time : nat64 };
  TooOld;
  Expired : record { ledger_time : nat64 };
  InsufficientFunds : record { balance : nat };
};
type ApproveResult = variant { Ok : nat; Err : ApproveError };

type HttpRequest = record {
  url : text;
  method : text;
  body : vec nat8;
  headers : vec record { text; text };
};
type HttpResponse = record {
  body : vec nat8;
  headers : vec record { text; text };
  status_code : nat16;
};

type Account = record {
    owner : principal;
    subaccount : opt Subaccount;
};

type TransferArg = record {
    from_subaccount : opt Subaccount;
    to : Account;
    amount : Tokens;
    fee : opt Tokens;
    memo : opt blob;
    created_at_time: opt Timestamp;
};

type TransferError = variant {
    BadFee : record { expected_fee : Tokens };
    BadBurn : record { min_burn_amount : Tokens };
    InsufficientFunds : record { balance : Tokens };
    TooOld;
    CreatedInFuture : record { ledger_time : nat64 };
    TemporarilyUnavailable;
    Duplicate : record { duplicate_of : BlockIndex };
    GenericError : record { error_code : nat; message : text };
};

type TransferResult = variant {
    Ok : BlockIndex;
    Err : TransferError;
};

// The value returned from the [icrc1_metadata] endpoint.
type MetadataValue = variant {
    Nat : nat;
    Int : int;
    Text : text;
    Blob : blob;
};

type FeatureFlags = record {
    icrc2 : bool;
};

// The initialization parameters of the Ledger
type InitArgs = record {
    minting_account : Account;
    fee_collector_account : opt Account;
    transfer_fee : nat;
    decimals : opt nat8;
    max_memo_length : opt nat16;
    token_symbol : text;
    token_name : text;
    metadata : vec record { text; MetadataValue };
    initial_balances : vec record { Account; nat };
    feature_flags : opt FeatureFlags;
    maximum_number_of_accounts : opt nat64;
    accounts_overflow_trim_quantity : opt nat64;
    archive_options : record {
        num_blocks_to_archive : nat64;
        max_transactions_per_response : opt nat64;
        trigger_threshold : nat64;
        max_message_size_bytes : opt nat64;
        cycles_for_archive_creation : opt nat64;
        node_max_memory_size_bytes : opt nat64;
        controller_id : principal;
    };
};

type ChangeFeeCollector = variant {
    Unset; SetTo: Account;
};

type UpgradeArgs = record {
    metadata : opt vec record { text; MetadataValue };
    token_symbol : opt text;
    token_name : opt text;
    transfer_fee : opt nat;
    change_fee_collector : opt ChangeFeeCollector;
    max_memo_length : opt nat16;
    feature_flags : opt FeatureFlags;
    maximum_number_of_accounts: opt nat64;
    accounts_overflow_trim_quantity: opt nat64;
};

type LedgerArg = variant {
    Init: InitArgs;
    Upgrade: opt UpgradeArgs;
};

type GetTransactionsRequest = record {
    // The index of the first tx to fetch.
    start : TxIndex;
    // The number of transactions to fetch.
    length : nat;
};

type GetTransactionsResponse = record {
    // The total number of transactions in the log.
    log_length : nat;

    // List of transaction that were available in the ledger when it processed the call.
    //
    // The transactions form a contiguous range, with the first transaction having index
    // [first_index] (see below), and the last transaction having index
    // [first_index] + len(transactions) - 1.
    //
    // The transaction range can be an arbitrary sub-range of the originally requested range.
    transactions : vec Transaction;

    // The index of the first transaction in [transactions].
    // If the transaction vector is empty, the exact value of this field is not specified.
    first_index : TxIndex;

    // Encoding of instructions for fetching archived transactions whose indices fall into the
    // requested range.
    //
    // For each entry `e` in [archived_transactions], `[e.from, e.from + len)` is a sub-range
    // of the originally requested transaction range.
    archived_transactions : vec record {
        // The index of the first archived transaction you can fetch using the [callback].
        start : TxIndex;

        // The number of transactions you can fetch using the callback.
        length : nat;

        // The function you should call to fetch the archived transactions.
        // The range of the transaction accessible using this function is given by [from]
        // and [len] fields above.
        callback : QueryArchiveFn;
    };
};


// A prefix of the transaction range specified in the [GetTransactionsRequest] request.
type TransactionRange = record {
    // A prefix of the requested transaction range.
    // The index of the first transaction is equal to [GetTransactionsRequest.from].
    //
    // Note that the number of transactions might be less than the requested
    // [GetTransactionsRequest.length] for various reasons, for example:
    //
    // 1. The query might have hit the replica with an outdated state
    //    that doesn't have the whole range yet.
    // 2. The requested range is too large to fit into a single reply.
    //
    // NOTE: the list of transactions can be empty if:
    //
    // 1. [GetTransactionsRequest.length] was zero.
    // 2. [GetTransactionsRequest.from] was larger than the last transaction known to
    //    the canister.
    transactions : vec Transaction;
};

// A function for fetching archived transaction.
type QueryArchiveFn = func (GetTransactionsRequest) -> (TransactionRange) query;

type Transaction = record {
  burn : opt Burn;
  kind : text;
  mint : opt Mint;
  approve : opt Approve;
  timestamp : nat64;
  transfer : opt Transfer;
};

type Burn = record {
  from : Account;
  memo : opt vec nat8;
  created_at_time : opt nat64;
  amount : nat;
  spender : opt Account;
};

type Mint = record {
  to : Account;
  memo : opt vec nat8;
  created_at_time : opt nat64;
  amount : nat;
};

type Transfer = record {
  to : Account;
  fee : opt nat;
  from : Account;
  memo : opt vec nat8;
  created_at_time : opt nat64;
  amount : nat;
  spender : opt Account;
};

type Value = variant { 
    Blob : blob; 
    Text : text; 
    Nat : nat;
    Nat64: nat64; 
    Int : int;
    Array : vec Value; 
    Map : Map; 
};

type Map = vec record { text; Value };

type Block = Value;

type GetBlocksArgs = record {
    // The index of the first block to fetch.
    start : BlockIndex;
    // Max number of blocks to fetch.
    length : nat;
};

// A prefix of the block range specified in the [GetBlocksArgs] request.
type BlockRange = record {
    // A prefix of the requested block range.
    // The index of the first block is equal to [GetBlocksArgs.start].
    //
    // Note that the number of blocks might be less than the requested
    // [GetBlocksArgs.length] for various reasons, for example:
    //
    // 1. The query might have hit the replica with an outdated state
    //    that doesn't have the whole range yet.
    // 2. The requested range is too large to fit into a single reply.
    //
    // NOTE: the list of blocks can be empty if:
    //
    // 1. [GetBlocksArgs.length] was zero.
    // 2. [GetBlocksArgs.start] was larger than the last block known to
    //    the canister.
    blocks : vec Block;
};

// A function for fetching archived blocks.
type QueryBlockArchiveFn = func (GetBlocksArgs) -> (BlockRange) query;

// The result of a "get_blocks" call.
type GetBlocksResponse = record {
    // The index of the first block in "blocks".
    // If the blocks vector is empty, the exact value of this field is not specified.
    first_index : BlockIndex;

    // The total number of blocks in the chain.
    // If the chain length is positive, the index of the last block is `chain_len - 1`.
    chain_length : nat64;

    // System certificate for the hash of the latest block in the chain.
    // Only present if `get_blocks` is called in a non-replicated query context.
    certificate : opt blob;

    // List of blocks that were available in the ledger when it processed the call.
    //
    // The blocks form a contiguous range, with the first block having index
    // [first_block_index] (see below), and the last block having index
    // [first_block_index] + len(blocks) - 1.
    //
    // The block range can be an arbitrary sub-range of the originally requested range.
    blocks : vec Block;

    // Encoding of instructions for fetching archived blocks.
    archived_blocks : vec record {
        // The index of the first archived block.
        start : BlockIndex;

        // The number of blocks that can be fetched.
        length : nat;

        // Callback to fetch the archived blocks.
        callback : QueryBlockArchiveFn;
    };
};

// Certificate for the block at `block_index`.
type DataCertificate = record {
    certificate : opt blob;
    hash_tree : blob;
};

type StandardRecord = record { url : text; name : text };

type TransferFromArgs = record {
    spender_subaccount : opt Subaccount;
    from : Account;
    to : Account;
    amount : Tokens;
    fee : opt Tokens;
    memo : opt blob;
    created_at_time: opt Timestamp;
};

type TransferFromResult = variant {
    Ok : BlockIndex;
    Err : TransferFromError;
};

type TransferFromError = variant {
    BadFee : record { expected_fee : Tokens };
    BadBurn : record { min_burn_amount : Tokens };
    InsufficientFunds : record { balance : Tokens };
    InsufficientAllowance : record { allowance : Tokens };
    TooOld;
    CreatedInFuture : record { ledger_time : nat64 };
    Duplicate : record { duplicate_of : BlockIndex };
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};

service : (ledger_arg : LedgerArg) -> {
    get_transactions : (GetTransactionsRequest) -> (GetTransactionsResponse) query;
    get_blocks : (GetBlocksArgs) -> (GetBlocksResponse) query;  
    get_data_certificate : () -> (DataCertificate) query; 

    icrc1_name : () -> (text) query;
    icrc1_symbol : () -> (text) query;
    icrc1_decimals : () -> (nat8) query;
    icrc1_metadata : () -> (vec record { text; MetadataValue }) query;
    icrc1_total_supply : () -> (Tokens) query;
    icrc1_fee : () -> (Tokens) query;
    icrc1_minting_account : () -> (opt Account) query;
    icrc1_balance_of : (Account) -> (Tokens) query;
    icrc1_transfer : (TransferArg) -> (TransferResult);
    icrc1_supported_standards : () -> (vec StandardRecord) query;
  
    icrc2_approve : (ApproveArgs) -> (ApproveResult);
    icrc2_allowance : (AllowanceArgs) -> (Allowance) query;
    icrc2_transfer_from : (TransferFromArgs) -> (TransferFromResult);
}