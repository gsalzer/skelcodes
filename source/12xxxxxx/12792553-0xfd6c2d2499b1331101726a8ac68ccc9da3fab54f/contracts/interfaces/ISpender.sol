pragma solidity ^0.6.0;

interface ISpender {
    function spendFromUser(address _user, address _tokenAddr, uint256 _amount) external;
    function spendFromUserTo(address _user, address _tokenAddr, address _receiverAddr, uint256 _amount) external;
}

