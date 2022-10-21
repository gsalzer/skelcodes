pragma solidity ^0.4.17;

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address _addr) constant public returns(uint256);
    function transfer(address _to, uint256 _value) public returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
