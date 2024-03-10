pragma solidity ^0.5.0;

interface GameInterface {
    function maxBet(uint _num, uint _bankRoll) external view returns(uint);

    function resultNumber(bytes32 _serverSeed, bytes32 _userSeed, uint _num) external view returns(uint);

    function userProfit(uint _num, uint _betValue, uint _resultNum) external view returns(int);

    function maxUserProfit(uint _num, uint _betValue) external view returns(int);
}

