pragma solidity ^0.6.4;

contract Anchor {
    mapping (bytes32 => uint) public merkleRoots;
    
    function setRoot(bytes32 rootHash) public returns (uint) {
        merkleRoots[rootHash] = block.number;
    }
}
