// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {IZap} from "contracts/lpaccount/Imports.sol";
import {IERC20} from "contracts/common/Imports.sol";
import {SafeERC20} from "contracts/libraries/Imports.sol";
import {
    ILiquidityGauge
} from "contracts/protocols/curve/common/interfaces/Imports.sol";
import {
    IBooster,
    IBaseRewardPool
} from "contracts/protocols/convex/common/interfaces/Imports.sol";

contract ConvexMigrationZap is IZap {
    using SafeERC20 for IERC20;

    string public constant override NAME = "convex-migration";
    address internal constant BOOSTER_ADDRESS =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    function deployLiquidity(uint256[] calldata) external override {
        revert("NOT_IMPLEMENTED");
    }

    /**
     * @param amount LP token amount
     * @param pid Convex Booster PID
     */
    function unwindLiquidity(uint256 amount, uint8 pid) external override {
        IBooster booster = IBooster(BOOSTER_ADDRESS);
        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        address lpToken = poolInfo.lptoken;
        address gauge = poolInfo.gauge;

        ILiquidityGauge liquidityGauge = ILiquidityGauge(gauge);
        liquidityGauge.withdraw(amount);

        uint256 lpBalance = IERC20(lpToken).balanceOf(address(this));
        IERC20(lpToken).safeApprove(BOOSTER_ADDRESS, 0);
        IERC20(lpToken).safeApprove(BOOSTER_ADDRESS, lpBalance);
        // deposit and mint staking tokens 1:1; bool is to stake
        booster.deposit(pid, lpBalance, true);
    }

    function claim() external override {
        revert("NOT_IMPLEMENTED");
    }

    function getLpTokenBalance(address)
        external
        view
        override
        returns (uint256)
    {
        revert("NOT_IMPLEMENTED");
    }

    function sortedSymbols() external view override returns (string[] memory) {
        revert("NOT_IMPLEMENTED");
    }

    function assetAllocations() public view override returns (string[] memory) {
        return new string[](0);
    }

    function erc20Allocations() public view override returns (IERC20[] memory) {
        return new IERC20[](0);
    }
}

