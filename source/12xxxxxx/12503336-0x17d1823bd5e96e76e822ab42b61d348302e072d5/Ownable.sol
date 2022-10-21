pragma solidity ^0.8.0; 

/*
 SPDX-License-Identifier: MIT
*/

contract Ownable {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = payable(msg.sender);
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = payable(address(0));
    }
}
