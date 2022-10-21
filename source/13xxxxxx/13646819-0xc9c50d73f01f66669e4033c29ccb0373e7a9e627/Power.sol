// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Power is Ownable {
    mapping(address => uint256) internal _powerOnes;

    constructor() public {
        _powerOnes[msg.sender] = 1;
    }

    modifier isPowerful() {
        require(_powerOnes[msg.sender] > 0, "Power: Insufficient power");
        _;
    }

    function addOne(address oneAddr) public onlyOwner {
        _powerOnes[oneAddr] = 1;
    }

    function removeOne(address oneAddr) public onlyOwner {
        require(oneAddr != owner(), "Trying to slay a god");
        delete _powerOnes[oneAddr];
    }
}

