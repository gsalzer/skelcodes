// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./RootKit.sol";
import "./IUniswapV2Router02.sol";
import "./IWrappedERC20.sol";
import "./IERC20.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Factory.sol";
import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./KETH.sol";
import "./SafeMath.sol";
import "./IWETH.sol";

/* ROOTKIT:
This receives RootKit from whereever
You can add ETH or KETH and we'll match it with RootKit from here for you
Then you get the liquidity tokens back
All in one shot
Ready for staking
Cheaper than buying first!
*/

contract RootKitLiquidityMatching is Owned, TokensRecoverable
{
    using SafeMath for uint256;

    RootKit immutable rootKit;
    IUniswapV2Router02 immutable uniswapV2Router;
    IWrappedERC20 immutable liquidityTokenWrapper;
    KETH immutable keth;
    IWETH immutable weth;

    uint16 public liquidityPercentForUser = 5000; // 100% = 10000

    constructor(RootKit _rootKit, IUniswapV2Router02 _uniswapV2Router, IWrappedERC20 _liquidityTokenWrapper, KETH _keth)
    {
        rootKit = _rootKit;
        uniswapV2Router = _uniswapV2Router;
        liquidityTokenWrapper = _liquidityTokenWrapper;
        keth = _keth;

        IWETH _weth = IWETH(_uniswapV2Router.WETH());
        weth = _weth;

        IERC20 _liquidityToken = _liquidityTokenWrapper.wrappedToken();
        _liquidityToken.approve(address(_liquidityTokenWrapper), uint256(-1));
        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        _keth.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_keth), uint256(-1));

        require (IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(_rootKit), address(_keth)) == address(_liquidityToken), "Sanity");
    }

    receive() external payable
    {
        require (msg.sender == address(keth));
    }

    function setLiquidityPercentForUser(uint16 _liquidityPercentForUser) public ownerOnly()
    {
        require (_liquidityPercentForUser <= 10000);
        
        liquidityPercentForUser = _liquidityPercentForUser;
    }

    function addLiquidityETH() public payable
    {
        uint256 amount = msg.value;
        require (amount > 0, "Zero amount");
        keth.deposit{ value: amount }();

        uint256 remainingKeth = addKethToLiquidity(amount);

        if (remainingKeth > 0) {
            keth.withdraw(remainingKeth);
            (bool success,) = msg.sender.call{ value: remainingKeth }("");
            require (success, "Transfer failed");
        }
    }

    function addLiquidityWETH(uint256 amount) public
    {
        require (amount > 0, "Zero amount");
        weth.transferFrom(msg.sender, address(this), amount);
        keth.depositTokens(amount);

        uint256 remainingKeth = addKethToLiquidity(amount);

        if (remainingKeth > 0) {
            keth.withdrawTokens(remainingKeth);
            weth.transfer(msg.sender, remainingKeth);
        }
    }

    function addLiquidityKETH(uint256 amount) public
    {
        require (amount > 0, "Zero amount");
        keth.transferFrom(msg.sender, address(this), amount);

        uint256 remainingKeth = addKethToLiquidity(amount);

        if (remainingKeth > 0) {
            keth.transfer(msg.sender, remainingKeth);
        }
    }

    function addKethToLiquidity(uint256 amount) private returns (uint256 remainingKeth)
    {
        (,,uint256 liquidity) = uniswapV2Router.addLiquidity(address(rootKit), address(keth), rootKit.balanceOf(address(this)), amount, 0, 0, address(this), block.timestamp);
        require (liquidity > 0, "No liquidity created (no available RootKit?)");
        liquidity = liquidity.mul(liquidityPercentForUser) / 10000;
        liquidityTokenWrapper.depositTokens(liquidity);
        liquidityTokenWrapper.transfer(msg.sender, liquidity);
        return keth.balanceOf(address(this));
    }
}
