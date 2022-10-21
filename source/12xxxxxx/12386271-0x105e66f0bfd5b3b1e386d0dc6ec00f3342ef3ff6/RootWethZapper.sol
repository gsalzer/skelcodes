// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./RootKit.sol";
import "./RootKitTransferGate.sol";
import "./TokensRecoverable.sol";

contract RootWethZapper is TokensRecoverable
{
    function go(IWETH weth, RootKit rootKit, uint256 wethAmount, uint256 rootKitAmount, IUniswapV2Router02 uniswapV2Router)
        public ownerOnly()
    {
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));
        gate.setUnrestricted(true);
        weth.transferFrom(msg.sender, address(this), wethAmount);
        rootKit.transferFrom(msg.sender, address(this), rootKitAmount);
        weth.approve(address(uniswapV2Router), wethAmount);
        rootKit.approve(address(uniswapV2Router), rootKitAmount);
        uniswapV2Router.addLiquidity(address(weth), address(rootKit), wethAmount, rootKitAmount, wethAmount, rootKitAmount, msg.sender, block.timestamp);
        gate.setUnrestricted(false);
    }
}
