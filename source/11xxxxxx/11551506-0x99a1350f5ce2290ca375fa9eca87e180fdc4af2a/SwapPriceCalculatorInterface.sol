// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;

interface ISwapPriceCalculator
{
    function calc(uint256 receivedEthAmount,
                  uint256 expectedTokensAmount,
                  uint16  slippage,
                  uint256 ethReserve,
                  uint256 tokensSold,
                  bool 	  excludeFee) external view returns (uint256 actualTokensAmount,
															 uint256 ethFeeAdd,
															 uint256 actualEthAmount);
}
