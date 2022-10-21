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
import "./KETH.sol";

contract WethToKethLiquidityZapper is TokensRecoverable
{
    IUniswapV2Router02 immutable uniswapV2Router;
    IERC31337 immutable wrappedWethRootKit;
    IUniswapV2Pair kethRootKit;
    IUniswapV2Pair wethRootKit;
    RootKit immutable rootKit;
    IWETH immutable weth;
    KETH immutable keth;
    
    constructor(IUniswapV2Router02 _uniswapV2Router, IERC31337 _wrappedWethRootKit, KETH _keth, RootKit _rootKit)
    {
        uniswapV2Router = _uniswapV2Router;
        wrappedWethRootKit = _wrappedWethRootKit;
        keth = _keth;
        rootKit = _rootKit;

        IUniswapV2Pair _wethRootKit = IUniswapV2Pair(address(_wrappedWethRootKit.wrappedToken()));
        wethRootKit = _wethRootKit;

        IWETH _weth = IWETH(_uniswapV2Router.WETH());
        weth = _weth;       

        kethRootKit = IUniswapV2Pair(IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_keth), address(_rootKit)));

        _wethRootKit.approve(address(_uniswapV2Router), uint256(-1));
        _keth.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_keth), uint256(-1));
        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        
        require (_wethRootKit.token0() == address(_rootKit) || _wethRootKit.token1() == address(_rootKit), "Sanity");
        require (_wethRootKit.token0() == address(_weth) || _wethRootKit.token1() == address(_weth), "Sanity");
    }

    function WethToKeth() public ownerOnly()
    {
        wrappedWethRootKit.sweepFloor(address(this));
        uint256 liquidity = wethRootKit.balanceOf(address(this));
        require (liquidity > 0, "Nothing unwrapped");       
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));
        gate.setUnrestricted(true);
        (uint256 amountRootKit, uint256 amountWeth) = uniswapV2Router.removeLiquidity(address(rootKit), address(weth), liquidity, 0, 0, address(this), block.timestamp);
        keth.depositTokens(amountWeth);
        (,,liquidity) = uniswapV2Router.addLiquidity(address(rootKit), address(keth), amountRootKit, amountWeth, 0, 0, address(this), block.timestamp);
        require (liquidity > 0, "Nothing wrapped");
        kethRootKit.transfer(msg.sender, liquidity);        
        uint256 balance = weth.balanceOf(address(this));
        if (balance > 0) { weth.transfer(msg.sender, balance ); }
        balance = keth.balanceOf(address(this));
        if (balance > 0) { keth.transfer(msg.sender, balance ); }
        balance = rootKit.balanceOf(address(this));
        if (balance > 0) { rootKit.transfer(msg.sender, balance ); }
        gate.setUnrestricted(false);
    }
}
