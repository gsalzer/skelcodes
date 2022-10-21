pragma solidity ^0.5.7;


contract Constants {

    uint256 public constant CAN_MINT_COINS = 1;
    uint256 public constant CAN_BURN_COINS = 2;
    uint256 public constant CAN_PAUSE_COINS = 3;
    uint256 public constant CAN_FINALIZE = 4;

    string public constant ERROR_ACCESS_DENIED = "ERROR_ACCESS_DENIED";
    string public constant ERROR_NOT_ALLOWED = "ERROR_NOT_ALLOWED";
}



