// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./abstract/AbstractLiquidityMiningStaking.sol";

contract LiquidityMiningStakingETH is AbstractLiquidityMiningStaking {
    function __LiquidityMiningStakingETH_init() external initializer {
        __LiquidityMiningStaking_init();
    }

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        rewardsToken = IERC20(_contractsRegistry.getBMIContract());
        bmiStaking = IBMIStaking(_contractsRegistry.getBMIStakingContract());
        stakingToken = _contractsRegistry.getSushiswapBMIToETHPairContract();
        liquidityMining = ILiquidityMining(_contractsRegistry.getLiquidityMiningContract());
        nftStakingAddress = _contractsRegistry.getNFTStakingContract();
        sushiswapMasterChefV2Address = _contractsRegistry.getSushiSwapMasterChefV2Contract();
    }
}

