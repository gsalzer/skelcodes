// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;

interface IUniswapV2Router01 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// solhint-disable-next-line no-empty-blocks
interface IUniswapV2Router02 is IUniswapV2Router01 {

}

