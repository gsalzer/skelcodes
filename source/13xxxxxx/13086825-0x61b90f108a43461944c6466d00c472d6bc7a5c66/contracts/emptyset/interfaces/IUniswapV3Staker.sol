// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV3Staker {
    struct IncentiveKey {
        IERC20 rewardToken;
        address pool;
        uint256 startTime;
        uint256 endTime;
        address refundee;
    }

    function createIncentive(IncentiveKey memory key, uint256 reward) external;
}

