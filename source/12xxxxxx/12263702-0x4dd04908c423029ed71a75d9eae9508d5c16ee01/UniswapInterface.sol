// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

interface UniswapI {
    
    function swapExactTokensForTokens(uint256,uint256,address[] calldata,address,uint256) external;

    function getAmountsOut(uint amountIn, address[] memory path) external returns (uint[] memory amounts);
}
