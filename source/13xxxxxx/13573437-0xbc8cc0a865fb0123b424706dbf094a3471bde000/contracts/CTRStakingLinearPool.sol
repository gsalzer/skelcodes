// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./pool/LinearPool.sol";

contract CTRStakingLinearPool is LinearPool {
    /**
     * @notice Initialize the contract, get called in the first time deploy
     * @param _rewardToken the reward token for the allocation pool and the accepted token for the linear pool
     */
    constructor(IERC20 _rewardToken) LinearPool(_rewardToken) {}
}

