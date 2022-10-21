// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface ISwapPriceCalculator
{
    function calc(uint256 fromAmount,
                  uint256 expectedToAmount,
                  uint16  slippage,
                  uint256 fromReserve,
                  uint256 toSoldAmount,
                  bool 	  excludeFee) external view returns (uint256 actualToAmount,
															 uint256 fromFeeAdd,
															 uint256 actualFromAmount);
}
