pragma solidity ^0.5.2;

contract ERC223ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}
