// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;


interface OneInchAgregator {
    function unoswap(address srcToken,uint256 amount,uint256 minReturn,bytes32[] calldata _pools) external payable returns(uint256 returnAmount);
    function uniswapV3Swap(uint256 amount,uint256 minReturn,uint256[] calldata pools) external payable returns(uint256 returnAmount); 
}

