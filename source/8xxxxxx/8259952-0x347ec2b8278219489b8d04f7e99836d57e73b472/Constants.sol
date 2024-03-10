pragma solidity ^0.5.7;


contract Constants {

    // Permissions constants
    uint256 public constant CAN_EXCHANGE_COINS = 1;
    uint256 public constant CAN_REGISTER_COINS = 2;
    uint256 public constant CAN_MINT_COINS = 3;
    uint256 public constant CAN_BURN_COINS = 4;
    uint256 public constant CAN_LOCK_COINS = 5;
    uint256 public constant PERMITTED_COINS = 6;

    // Contract Registry keys

    //public block-chain
    uint256 public constant CONTRACT_TOKEN = 1;
    uint256 public constant CONTRACT_EXCHANGE = 2;
    uint256 public constant CONTRACT_WITHDRAW = 3;
    uint256 public constant COIN_HOLDER = 4;



    uint256 public constant PERCENTS_ABS_MAX = 1e4;
    uint256 public constant USD_PRECISION = 1e5;

    string public constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
    string public constant ERROR_NO_CONTRACT = "ERROR_NO_CONTRACT";
    string public constant ERROR_NOT_AVAILABLE = "ERROR_NOT_AVAILABLE";
    string public constant ERROR_WRONG_AMOUNT = "ERROR_WRONG_AMOUNT";
    /*solium-disable-next-line*/
    string public constant ERROR_NOT_PERMITTED_COIN = "ERROR_NOT_PERMITTED_COIN";
    /*solium-disable-next-line*/
    string public constant ERROR_BALANCE_IS_NOT_ALLOWED = "BALANCE_IS_NOT_ALLOWED";
    string public constant ERROR_COIN_REGISTERED = "ERROR_COIN_REGISTERED";

    // Campaign Sates
    enum RequestState{
        Pending,
        PaidPartially,
        FullyPaid,
        Rejected,
        Refunded,
        Undefined,
        Canceled
    }
}


