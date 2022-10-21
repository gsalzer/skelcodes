pragma solidity ^0.5.9;

contract CodeHash {
    function soul(address usr) public view returns (bytes32 tag)
    {
        assembly { tag := extcodehash(usr) }
    }
}
