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

contract KethToWethLiquidityZapper is TokensRecoverable
{
    IUniswapV2Router02 immutable uniswapV2Router;
    IERC31337 immutable wrappedKethRootKit;
    IUniswapV2Pair kethRootKit;
    IUniswapV2Pair wethRootKit;
    RootKit immutable rootKit;
    IWETH immutable weth;
    KETH immutable keth;
    
    constructor(IUniswapV2Router02 _uniswapV2Router, IERC31337 _wrappedKethRootKit, RootKit _rootKit)
    {
        uniswapV2Router = _uniswapV2Router;
        wrappedKethRootKit = _wrappedKethRootKit;
        rootKit = _rootKit;

        IUniswapV2Pair _kethRootKit = IUniswapV2Pair(address(_wrappedKethRootKit.wrappedToken()));
        kethRootKit = _kethRootKit;

        IWETH _weth = IWETH(_uniswapV2Router.WETH());
        weth = _weth;        
        
        KETH  _keth = KETH(payable(_kethRootKit.token0() == address(_rootKit) ? _kethRootKit.token1() :_kethRootKit.token0()));
        keth = _keth;

        wethRootKit = IUniswapV2Pair(IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_weth), address(_rootKit)));

        _kethRootKit.approve(address(_uniswapV2Router), uint256(-1));
        _keth.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        
        require (_kethRootKit.token0() == address(_rootKit) || _kethRootKit.token1() == address(_rootKit), "Sanity");
        require (_kethRootKit.token0() != address(_weth) && _kethRootKit.token1() != address(_weth), "Sanity");
    }

    function go() public ownerOnly()
    {
        wrappedKethRootKit.sweepFloor(address(this));
        uint256 liquidity = kethRootKit.balanceOf(address(this));
        require (liquidity > 0, "Nothing unwrapped");       
        RootKitTransferGate gate = RootKitTransferGate(address(rootKit.transferGate()));
        gate.setUnrestricted(true);        
        (uint256 amountRootKit, uint256 amountKeth) = uniswapV2Router.removeLiquidity(address(rootKit), address(keth), liquidity, 0, 0, address(this), block.timestamp);
        keth.withdrawTokens(amountKeth);
        (,,liquidity) = uniswapV2Router.addLiquidity(address(rootKit), address(weth), amountRootKit, amountKeth, 0, 0, address(this), block.timestamp);
        require (liquidity > 0, "Nothing wrapped");
        wethRootKit.transfer(msg.sender, liquidity);
        uint256 balance = weth.balanceOf(address(this));
        if (balance > 0) { weth.transfer(msg.sender, balance ); }
        balance = keth.balanceOf(address(this));
        if (balance > 0) { keth.transfer(msg.sender, balance ); }
        balance = rootKit.balanceOf(address(this));
        if (balance > 0) { rootKit.transfer(msg.sender, balance ); }
        gate.setUnrestricted(false);
    }
}
