// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

import "IEligibility.sol";

contract AmaluEligibility is IEligibility {

    mapping(uint => mapping(address => uint)) public timesWithdrawn;
    mapping(uint => uint) public maxWithdrawals;
    address public gateMaster;
    address public management;

    modifier managementOnly() {
        require (msg.sender == management, 'Only management may call this');
        _;
    }

    constructor (address _mgmt, address _gateMaster) {
        gateMaster = _gateMaster;
        management = _mgmt;
    }

    // change the management key
    function setManagement(address newMgmt) external managementOnly {
        management = newMgmt;
    }

    function addGate(uint index, uint max) external managementOnly {
        maxWithdrawals[index] = max;
    }

    function getGate(uint index) external view returns (uint) {
        return maxWithdrawals[index];
    }

    function isEligible(uint index, address recipient, bytes32[] memory) public override view returns (bool eligible) {
        return timesWithdrawn[index][recipient] < maxWithdrawals[index];
    }

    function passThruGate(uint index, address recipient, bytes32[] memory) external override {
        require(msg.sender == gateMaster, "Only gatemaster may call this.");

        // close re-entrance gate, prevent double withdrawals
        require(isEligible(index, recipient, new bytes32[](0)), "Address is not eligible");

        timesWithdrawn[index][recipient] += 1;
    }
}

