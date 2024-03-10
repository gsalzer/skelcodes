// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./Owned.sol";
import "./KETH.sol";
import "./RootKitTransferGate.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Factory.sol";

contract RootKitDirect is Owned, TokensRecoverable
{
    KETH immutable keth;
    RootKit immutable rootKit;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;

    constructor(KETH _keth, RootKit _rootKit, IUniswapV2Router02 _uniswapV2Router)
    {
        keth = _keth;
        rootKit = _rootKit;
        uniswapV2Router = _uniswapV2Router;

        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());

        _keth.approve(address(_uniswapV2Router), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
    }

    receive() external payable
    {
        require (msg.sender == address(keth));
    }

    function estimateBuy(uint256 ethAmountIn) public view returns (uint256 rootKitAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(keth);
        path[1] = address(rootKit);
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), ethAmountIn, path);
        return amounts[1];
    }

    function estimateSell(uint256 rootKitAmountIn) public view returns (uint256 ethAmount)
    {
        address[] memory path = new address[](2);
        path[0] = address(rootKit);
        path[1] = address(keth);
        (uint256[] memory amounts) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), rootKitAmountIn, path);
        return amounts[1];
    }

    function easyBuy() public payable returns (uint256 rootKitAmount)
    {
        return buy(estimateBuy(msg.value) * 98 / 100);
    }

    function easySell(uint256 rootKitAmountIn) public returns (uint256 ethAmount)
    {
        return sell(rootKitAmountIn, estimateSell(rootKitAmountIn) * 98 / 100);
    }

    function buy(uint256 amountOutMin) public payable returns (uint256 rootKitAmount)
    {
        uint256 amount = msg.value;
        require (amount > 0, "Send ETH to buy");
        keth.deposit{ value: amount }();
        address[] memory path = new address[](2);
        path[0] = address(keth);
        path[1] = address(rootKit);
        (uint256[] memory amounts) = uniswapV2Router.swapExactTokensForTokens(amount, amountOutMin, path, msg.sender, block.timestamp);
        return amounts[0];
    }

    function sell(uint256 rootKitAmountIn, uint256 amountOutMin) public returns (uint256 ethAmount)
    {
        require (rootKitAmountIn > 0, "Nothing to sell");
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));

        // to avoid double taxation
        gate.setUnrestricted(true);
        rootKit.transferFrom(msg.sender, address(this), rootKitAmountIn);
        gate.setUnrestricted(false);

        address[] memory path = new address[](2);
        path[0] = address(rootKit);
        path[1] = address(keth);
        (uint256[] memory amounts) = uniswapV2Router.swapExactTokensForTokens(rootKitAmountIn, amountOutMin, path, address(this), block.timestamp);
        keth.withdraw(amounts[1]);
        (bool success,) = msg.sender.call{ value: amounts[1] }("");
        require (success, "Transfer failed");
        return amounts[1];
    }
}
