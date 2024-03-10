// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from "./IERC20.sol";

import { IAddressRegistry } from "./IAddressRegistry.sol";
import { IAvalanche } from "./IAvalanche.sol";
import { IFROST } from "./IFROST.sol";
import { ReentrancyGuard } from "./ReentrancyGuard.sol";
import { UniswapBase } from "./UniswapBase.sol";

contract PoolBase is UniswapBase, ReentrancyGuard {

    uint256 internal constant SECONDS_PER_YEAR = 360 * 24 * 60 * 60; // std business yr, used to calculatee APR

    // Internal function to safely transfer tokens in case there is a rounding error
    function _safeTokenTransfer(
        address _token,
        address _to, 
        uint256 _amount
    ) 
        internal
    {
        uint256 tokenBalance = IERC20(_token).balanceOf(address(this));
        if (_amount > tokenBalance) {
            IERC20(_token).safeTransfer(_to, tokenBalance);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
    }

    // shared function to calculate fixed apr frost rewards
    //  used in both avalanche and slopes
    function _calculatePendingRewards(
        uint256 _lastReward,
        uint256 _supply,
        uint256 _tokenPrice,
        uint256 _weight
    )
        internal
        view
        returns (uint256)
    {
        uint256 secondsElapsed = block.timestamp - _lastReward;

        // get FROST uniswap price
        uint256 frostPrice = _getTokenPrice(frostAddress(), frostPoolAddress());

        uint256 scaledTotalLiquidityValue = _supply * _tokenPrice; // total value pooled tokens
        uint256 fixedApr = _weight * IFROST(frostAddress()).currentBaseRate();
        uint256 yearlyRewards = ((fixedApr / 100) * scaledTotalLiquidityValue) / frostPrice; // instantaneous yearly frost payout
        uint256 rewardsPerSecond = yearlyRewards / SECONDS_PER_YEAR; // instantaneous frost rewards per second 
        return secondsElapsed * rewardsPerSecond;
    }
}
