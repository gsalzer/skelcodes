pragma solidity >= 0.5.3 < 0.6.0;

//  ERC223 Receiving Contract contarct
//  - interface for ERC223 token's receiving smart contract
contract ERC223ReceivingContract {
    function tokenFallback(address from, uint256 value, bytes memory data) public;
}
