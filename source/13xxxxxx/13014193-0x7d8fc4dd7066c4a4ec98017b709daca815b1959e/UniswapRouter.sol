pragma solidity ^0.8.6;

// SPDX-License-Identifier: Apache-2.0

interface IUniswapV2Router {
    
    function WETH() external pure returns (address);
    
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
}
