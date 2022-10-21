/*
PoolInfo

https://github.com/gysr-io/core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "../interfaces/IPool.sol";
import "../interfaces/IStakingModule.sol";
import "../interfaces/IRewardModule.sol";

/**
 * @title Pool info library
 *
 * @notice this implements the Pool info library, which provides read-only
 * convenience functions to query additional information and metadata
 * about the core Pool contract.
 */
library PoolInfo {
    /**
     * @notice get information about the underlying staking and reward modules
     * @param pool address of Pool contract
     * @return staking module address
     * @return reward module address
     * @return staking module type
     * @return reward module type
     */
    function modules(address pool)
        public
        view
        returns (
            address,
            address,
            address,
            address
        )
    {
        IPool p = IPool(pool);
        IStakingModule s = IStakingModule(p.stakingModule());
        IRewardModule r = IRewardModule(p.rewardModule());
        return (address(s), address(r), s.factory(), r.factory());
    }
}

