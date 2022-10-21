// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

interface IVault
{
    function balancePriceBase(uint256 amount, uint256 minAmountOut) external;
    function balancePriceElite(uint256 amount, uint256 minAmountOut) external;
    function removeBuyAndTax(uint256 amount, uint256 minAmountOut, address token, uint16 tax, uint256 time) external;
    function buyAndTax(address token, uint256 amountToSpend, uint256 minAmountOut, uint16 tax, uint256 time) external;
    function sweepFloor() external;
    function zapEliteToBase(uint256 liquidity) external;
    function zapBaseToElite(uint256 liquidity) external;
    function wrapToElite(uint256 baseAmount) external;
    function unwrapElite(uint256 eliteAmount) external;
    function addLiquidity(address eliteOrBase, uint256 baseAmount) external;
    function removeLiquidity(address eliteOrBase, uint256 tokens) external;    
    function buyRooted(address token, uint256 amountToSpend, uint256 minAmountOut) external;
    function sellRooted(address token, uint256 amountToSpend, uint256 minAmountOut) external;  
}
