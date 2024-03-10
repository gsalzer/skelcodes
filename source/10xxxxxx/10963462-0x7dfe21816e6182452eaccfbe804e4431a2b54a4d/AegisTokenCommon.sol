pragma solidity ^0.5.16;

import "./AegisComptrollerInterface.sol";
import "./InterestRateModel.sol";

contract AegisTokenCommon {
    bool internal reentrant;

    string public name;
    string public symbol;
    uint public decimals;
    address payable public admin;
    address payable public pendingAdmin;
    address payable public liquidateAdmin;

    uint internal constant borrowRateMaxMantissa = 0.0005e16;
    uint internal constant reserveFactorMaxMantissa = 1e18;
    
    AegisComptrollerInterface public comptroller;
    InterestRateModel public interestRateModel;
    
    uint internal initialExchangeRateMantissa;
    uint public reserveFactorMantissa;
    uint public accrualBlockNumber;
    uint public borrowIndex;
    uint public totalBorrows;
    uint public totalReserves;
    uint public totalSupply;
    
    mapping (address => uint) internal accountTokens;
    mapping (address => mapping (address => uint)) internal transferAllowances;

    struct BorrowBalanceInfomation {
        uint principal;
        uint interestIndex;
    }
    mapping (address => BorrowBalanceInfomation) internal accountBorrows;
}
