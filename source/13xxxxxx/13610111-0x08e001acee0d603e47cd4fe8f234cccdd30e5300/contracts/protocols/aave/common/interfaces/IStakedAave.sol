// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.11;

import {IDetailedERC20} from "contracts/common/Imports.sol";

interface IStakedAave is IDetailedERC20 {
    /**
     * Stakes `amount` of AAVE tokens, sending the stkAAVE to `to`
     * Note: the msg.sender must already have a balance of AAVE token.
     */
    function stake(address to, uint256 amount) external;

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param to Address to redeem to
     * @param amount Amount to redeem
     */
    function redeem(address to, uint256 amount) external;

    /**
     * @dev Activates the cooldown period to unstake
     * - It can't be called if the user is not staking
     */
    function cooldown() external;

    /**
     * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
     * @param to Address to stake for
     * @param amount Amount to stake
     */
    function claimRewards(address to, uint256 amount) external;

    /**
     * Returns the current minimum cool down time needed to
     * elapse before a staker is able to unstake their tokens.
     * As of October 2020, the current COOLDOWN_SECONDS value is
     * 864000 seconds (i.e. 10 days). This value should always
     * be checked directly from the contracts.
     */
    //solhint-disable-next-line func-name-mixedcase
    function COOLDOWN_SECONDS() external view returns (uint256);

    /**
     * Returns the maximum window of time in seconds that a staker can
     * redeem() their stake once a cooldown() period has been completed.
     * As of October 2020, the current UNSTAKE_WINDOW value is
     * 172800 seconds (i.e. 2 days). This value should always be checked
     * directly from the contracts.
     */
    //solhint-disable-next-line func-name-mixedcase
    function UNSTAKE_WINDOW() external view returns (uint256);

    /**
     * @notice Returns the total rewards that are pending to be claimed by a staker.
     * @param staker the staker's address
     */
    function getTotalRewardsBalance(address staker)
        external
        view
        returns (uint256);

    function stakersCooldowns(address staker) external view returns (uint256);
}

