// SPDX-License-Identifier: MIT AND AGPL-3.0-only
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract Constants {

    IERC20 internal LP_TOKEN;
    IERC20 internal DOM_TOKEN;

    uint256 public STAKING_START_TIMESTAMP;
    uint256 internal constant STAKING_PERIOD = 7 days;
    uint256 internal constant REWARD_PERIOD = 120 days;
    uint256 internal LSP_EXPIRATION;

    uint256 public TOTAL_DOM;
}

