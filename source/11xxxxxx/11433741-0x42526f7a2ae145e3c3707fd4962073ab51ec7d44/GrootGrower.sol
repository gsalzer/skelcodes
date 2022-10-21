// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./GrootKit.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./UniswapV2Library.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract GrootGrower is TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event GrootGrew(uint32 growCount);

    GrootKit immutable grootKit;
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    IERC20 immutable otherToken;
    IUniswapV2Pair immutable uniswapV2Pair;

    struct GrowParameters
    {
        uint32 nextGrowTimestamp;
        uint32 growInterval;
        uint16 redeemPercent; // 100% = 10000
        uint16 buyPercent; // 100% = 10000 ... buy percent of reserves after redemption
        uint32 growCount;
    }
    GrowParameters public parameters;

    function secondsUntilCanGrow() public view returns (uint32)
    {
        uint256 next = parameters.nextGrowTimestamp;
        return uint32(block.timestamp >= next ? 0 : next - block.timestamp);
    }

    constructor(GrootKit _grootKit, IERC20 _otherToken, IUniswapV2Router02 _uniswapV2Router)
    {
        grootKit = _grootKit;
        uniswapV2Router = _uniswapV2Router;
        otherToken = _otherToken;

        IUniswapV2Factory _uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        uniswapV2Factory = _uniswapV2Factory;

        IUniswapV2Pair _uniswapV2Pair = IUniswapV2Pair(UniswapV2Library.pairFor(address(_uniswapV2Factory), address(_grootKit), address(_otherToken)));
        uniswapV2Pair = _uniswapV2Pair;

        _grootKit.approve(address(_uniswapV2Router), uint256(-1));
        _otherToken.safeApprove(address(_uniswapV2Router), uint256(-1));
        _uniswapV2Pair.approve(address(_uniswapV2Router), uint256(-1));
    }

    function setParameters(uint32 _growInterval, uint16 _redeemPercent, uint16 _buyPercent) public ownerOnly()
    {
        require (_redeemPercent <= 10000 && _buyPercent <= 10000);

        parameters = GrowParameters({ 
            nextGrowTimestamp: uint32(block.timestamp + _growInterval),
            growInterval: _growInterval,
            redeemPercent: _redeemPercent,
            buyPercent: _buyPercent,
            growCount: parameters.growCount
        });
    }

    function pricePerGroot() public view returns (uint256)
    {
        address[] memory pair = new address[](2);
        pair[0] = address(grootKit);
        pair[1] = address(otherToken);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), 1 ether, pair);
        return amounts[1];
    }

    function grow() public
    {
        require (msg.sender == tx.origin, "Please select all images with a bicycle");
        GrowParameters memory params = parameters;
        require (params.growInterval > 0 && params.redeemPercent > 0 && params.buyPercent > 0 && uniswapV2Pair.balanceOf(address(this)) > 10000, "Groot has stopped growing");
        require (block.timestamp >= params.nextGrowTimestamp, "Too early to grow");
        params.nextGrowTimestamp = uint32(block.timestamp + params.growInterval);
        emit GrootGrew(++params.growCount);
        parameters = params;

        bool wasLocked = grootKit.liquidityPairLocked(uniswapV2Pair);
        if (wasLocked) { grootKit.setLiquidityLock(uniswapV2Pair, false); }
        
        uniswapV2Router.removeLiquidity(
            address(grootKit), 
            address(otherToken), 
            uniswapV2Pair.balanceOf(address(this)) * params.redeemPercent / 10000,
            0,
            0,
            address(this),
            block.timestamp);

        address[] memory path = new address[](2);
        path[0] = address(otherToken);
        path[1] = address(grootKit);
        uniswapV2Router.swapExactTokensForTokens(
            otherToken.balanceOf(address(uniswapV2Pair)) * params.buyPercent / 10000,
            0,
            path,
            address(this),
            block.timestamp);

        uniswapV2Router.addLiquidity(
            address(grootKit),
            address(otherToken),
            grootKit.balanceOf(address(this)),
            otherToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp);

        grootKit.burn();

        if (wasLocked) { grootKit.setLiquidityLock(uniswapV2Pair, true); }
    }
}
