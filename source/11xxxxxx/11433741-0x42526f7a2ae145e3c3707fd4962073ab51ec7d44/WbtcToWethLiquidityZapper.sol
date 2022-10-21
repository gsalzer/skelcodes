// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./RootKit.sol";
import "./IERC31337.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";
import "./IUniswapV2Pair.sol";
import "./IERC20.sol";
import "./RootKitTransferGate.sol";

import "./UniswapV2Library.sol";

contract WbtcToWethLiquidityZapper is TokensRecoverable
{
    IUniswapV2Router02 immutable uniswapV2Router;
    IERC31337 immutable wrappedWbtcRootKit;
    IUniswapV2Pair wbtcRootKit;
    IUniswapV2Pair wethRootKit;
    RootKit immutable rootKit;
    IWETH immutable weth;
    IERC20 immutable wbtc;
    
    constructor(IUniswapV2Router02 _uniswapV2Router, IERC31337 _wrappedWbtcRootKit, RootKit _rootKit)
    {
        uniswapV2Router = _uniswapV2Router;
        wrappedWbtcRootKit = _wrappedWbtcRootKit;
        rootKit = _rootKit;

        IUniswapV2Pair _wbtcRootKit = IUniswapV2Pair(address(_wrappedWbtcRootKit.wrappedToken()));
        wbtcRootKit = _wbtcRootKit;

        IWETH _weth = IWETH(_uniswapV2Router.WETH());
        weth = _weth;
        
        IERC20 _wbtc = IERC20(_wbtcRootKit.token0() == address(_rootKit) ? _wbtcRootKit.token1() : _wbtcRootKit.token0());
        wbtc = _wbtc;

        wethRootKit = IUniswapV2Pair(IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_weth), address(_rootKit)));

        _wbtcRootKit.approve(address(_uniswapV2Router), uint256(-1));
        _wbtc.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        
        require (_wbtcRootKit.token0() == address(_rootKit) || _wbtcRootKit.token1() == address(_rootKit), "Sanity");
        require (_wbtcRootKit.token0() != address(_weth) && _wbtcRootKit.token1() != address(_weth), "Sanity");
    }

    function go() public ownerOnly()
    {
        wrappedWbtcRootKit.sweepFloor(address(this));
        uint256 liquidity = wbtcRootKit.balanceOf(address(this));
        require (liquidity > 0, "Nothing unwrapped");
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));
        gate.setUnrestricted(true);
        (uint256 amountRootKit, uint256 amountWbtc) = uniswapV2Router.removeLiquidity(address(rootKit), address(wbtc), liquidity, 0, 0, address(this), block.timestamp);
        address[] memory path = new address[](2);
        path[0] = address(wbtc);
        path[1] = address(weth);
        (uint256[] memory amounts) = uniswapV2Router.swapExactTokensForTokens(amountWbtc, 0, path, address(this), block.timestamp);
        (,,liquidity) = uniswapV2Router.addLiquidity(address(rootKit), address(weth), amountRootKit, amounts[1], 0, 0, address(this), block.timestamp);
        require (liquidity > 0, "Nothing wrapped");
        wethRootKit.transfer(msg.sender, liquidity);
        uint256 balance = weth.balanceOf(address(this));
        if (balance > 0) { weth.transfer(msg.sender, balance ); }
        balance = wbtc.balanceOf(address(this));
        if (balance > 0) { wbtc.transfer(msg.sender, balance ); }
        balance = rootKit.balanceOf(address(this));
        if (balance > 0) { rootKit.transfer(msg.sender, balance ); }
        gate.setUnrestricted(false);
    }
}
