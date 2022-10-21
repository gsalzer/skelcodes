// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;
pragma abicoder v2;

import "@openzeppelin/contracts/governance/TimelockController.sol";

contract Timelock is TimelockController {
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) TimelockController(minDelay, proposers,executors ) {

    }
}

