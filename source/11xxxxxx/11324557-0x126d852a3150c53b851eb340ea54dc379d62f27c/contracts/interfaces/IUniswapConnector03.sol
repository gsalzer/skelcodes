// SPDX-License-Identifier: MIT
pragma solidity 0.6.2;

import {
    IUniswapV2Router02
} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {
    IUniswapV2Factory
} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import { ITrader } from "@primitivefi/contracts/contracts/option/interfaces/ITrader.sol";
import { IOption, IERC20 } from "@primitivefi/contracts/contracts/option/interfaces/IOption.sol";

interface IUniswapConnector03 {
    // ==== Combo Operations ====

    function mintShortOptionsThenSwapToTokens(
        IOption optionToken,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (bool);

    // ==== Flash Functions ====

    function flashCloseLongOptionsThenSwap(
        address pairAddress,
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 minPayout,
        address[] calldata path,
        address to
    ) external returns (uint256, uint256);

    function flashMintShortOptionsThenSwap(
        address pairAddress,
        address optionAddress,
        uint256 flashLoanQuantity,
        uint256 maxPremium,
        address[] calldata path,
        address to
    ) external returns (uint256, uint256);

    function openFlashLong(
        IOption optionToken,
        uint256 amountOptions,
        uint256 amountOutMin
    ) external returns (bool);

    function closeFlashLong(
        IOption optionToken,
        uint256 amountRedeems,
        uint256 minPayout
    ) external returns (bool);

    // ==== Liquidity Functions ====

    function addShortLiquidityWithUnderlying(
        address optionAddress,
        uint256 quantityOptions,
        uint256 amountBMax,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeShortLiquidityThenCloseOptions(
        address optionAddress,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256, uint256);

    // ==== Management Functions ====

    function deployUniswapMarket(address optionAddress, address otherToken)
        external
        returns (address);

    // ==== View ====

    function getUniswapMarketForTokens(address token0, address token1)
        external
        view
        returns (address);

    function router() external view returns (IUniswapV2Router02);

    function factory() external view returns (IUniswapV2Factory);

    function trader() external view returns (ITrader);

    function getName() external pure returns (string memory);

    function getVersion() external pure returns (uint8);
}

