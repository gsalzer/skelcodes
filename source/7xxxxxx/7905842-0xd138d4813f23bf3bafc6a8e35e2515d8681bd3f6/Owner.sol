pragma solidity ^0.5.0;

contract Owner {
    address public owner;

    constructor () public {
        owner = msg.sender;
    }

    // isOwner checks whether the sender is the owner
    modifier isOwner() {
        require (owner == msg.sender, "Sender is not owner");
        _;
    }
}
