
pragma solidity ^0.4.25;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}
