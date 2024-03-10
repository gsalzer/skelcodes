// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "../interfaces/helpers/IPriceFeed.sol";

import "../abstract/AbstractDependant.sol";

contract PriceFeed is IPriceFeed, AbstractDependant {
    IUniswapV2Router02 public uniswapRouter;

    address public wethToken;
    address public bmiToken;
    address public usdtToken;

    function setDependencies(IContractsRegistry _contractsRegistry)
        external
        override
        onlyInjectorOrZero
    {
        uniswapRouter = IUniswapV2Router02(_contractsRegistry.getUniswapRouterContract());
        wethToken = _contractsRegistry.getWETHContract();
        bmiToken = _contractsRegistry.getBMIContract();
        usdtToken = _contractsRegistry.getUSDTContract();
    }

    function howManyBMIsInUSDT(uint256 usdtAmount) external view override returns (uint256) {
        if (usdtAmount == 0) {
            return 0;
        }

        address[] memory pairs = new address[](3);
        pairs[0] = usdtToken;
        pairs[1] = wethToken;
        pairs[2] = bmiToken;

        uint256[] memory amounts = uniswapRouter.getAmountsOut(usdtAmount, pairs);

        return amounts[amounts.length - 1];
    }

    function howManyUSDTsInBMI(uint256 bmiAmount) external view override returns (uint256) {
        if (bmiAmount == 0) {
            return 0;
        }

        address[] memory pairs = new address[](3);
        pairs[0] = bmiToken;
        pairs[1] = wethToken;
        pairs[2] = usdtToken;

        uint256[] memory amounts = uniswapRouter.getAmountsOut(bmiAmount, pairs);

        return amounts[amounts.length - 1];
    }
}

