pragma solidity ^0.5.0;

contract Erc20 {
    event Transfer(address indexed src, address indexed dst, uint wad);
    function balanceOf(address guy) public view returns (uint);
    function transfer(address dst, uint wad) public returns (bool);
}
