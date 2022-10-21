// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// We can't use the default implementation of OpenZeppelin's Ownable because it uses a constructor which doesn't work with Proxy contracts

abstract contract Ownable {
    address internal _owner;

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    constructor () {
        _owner = msg.sender;
    }

    function SetOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}

