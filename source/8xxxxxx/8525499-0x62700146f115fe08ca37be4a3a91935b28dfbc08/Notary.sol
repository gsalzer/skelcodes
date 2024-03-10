pragma solidity 0.5.11;

contract Notary {
    mapping (bytes32 => bool) public hashes ;
    
    function register(bytes32 _hash) public {
        hashes[_hash] = true;
    }
    
    function check(bytes32 _hash) public view returns (bool) {
        return hashes[_hash];
    }
}
