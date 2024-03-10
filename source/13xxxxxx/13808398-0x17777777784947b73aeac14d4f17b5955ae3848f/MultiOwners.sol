// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract MultiOwners is Ownable {
    mapping(address => uint256) internal _ownerGroup;

    constructor() {
        transferOwnership(tx.origin);
        _ownerGroup[_msgSender()] = 1;
        _ownerGroup[tx.origin] = 1;
    }

    modifier isOwner() {
        require(_ownerGroup[_msgSender()] > 0, "Owners: Insufficient power");
        _;
    }

    function addOne(address oneAddr) public onlyOwner {
        _ownerGroup[oneAddr] = 1;
    }

    function removeOne(address oneAddr) public onlyOwner {
        require(oneAddr != owner(), "Trying to slay a god");
        delete _ownerGroup[oneAddr];
    }
}

