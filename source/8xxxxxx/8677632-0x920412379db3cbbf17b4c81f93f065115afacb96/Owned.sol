pragma solidity ^0.5.8;

contract Owned {
    constructor() public { owner = msg.sender; }
    address payable public owner;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
}

