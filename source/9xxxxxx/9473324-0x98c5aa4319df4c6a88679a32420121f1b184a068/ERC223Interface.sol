pragma solidity >= 0.5.3 < 0.6.0;

//  ERC223 Interface
//  - interface for ERC223 token functions
contract ERC223Interface {
    uint public _totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool success);
    function transfer(address to, uint256 value, bytes memory data) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint256 value, bytes data);
}
