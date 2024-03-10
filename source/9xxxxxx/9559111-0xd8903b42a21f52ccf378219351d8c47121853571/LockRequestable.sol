pragma solidity ^0.4.24;

contract LockRequestable {

    // MEMBERS
    uint256 public lockRequestCount;

    // CONSTRUCTOR
    constructor() public {
        lockRequestCount = 0;
    }

    // FUNCTIONS
    function generateLockId() internal returns (bytes32 lockId) {
        return keccak256(
            abi.encodePacked(blockhash(block.number - 1), address(this), ++lockRequestCount)
        );
    }
}
