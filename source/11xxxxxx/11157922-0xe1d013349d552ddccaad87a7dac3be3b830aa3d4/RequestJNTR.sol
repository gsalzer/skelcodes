// SPDX-License-Identifier: No License (None)
pragma solidity ^0.6.9;

import "./Ownable.sol";

contract RequestJNTR is Ownable {
    mapping(address => bool) public isReceived; // user => isReceived
    uint256 public fee;
    address payable public system;  // system address mey change fee amount and receive fee
    event TokenRequest(address indexed user, uint256 amount);

    modifier onlySystem() {
        require(msg.sender == system, "Caller is not the system");
        _;
    }

    constructor (address payable _system, uint256 _fee) public {
        system = _system;
        fee = _fee;
    }

    function setFee(uint256 _fee) external onlySystem returns(bool) {
        fee = _fee;
        return true;
    }

    function setSystem(address payable _system) external onlyOwner returns(bool) {
        system = _system;
        return true;
    }

    function tokenRequest() public payable {
        require(fee <= msg.value, "Not enough value");
        require(!isReceived[msg.sender], "You already requested tokens");
        isReceived[msg.sender] = true;
        system.transfer(msg.value);
        emit TokenRequest(msg.sender, msg.value);
    }
}
