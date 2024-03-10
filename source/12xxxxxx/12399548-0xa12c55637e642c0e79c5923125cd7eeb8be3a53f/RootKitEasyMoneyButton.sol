// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";
import "./UniswapV2Library.sol";
import "./IUniswapV2Pair.sol";
import "./IWETH.sol";
import "./KETH.sol";
import "./RootKit.sol";
import "./IUniswapV2Factory.sol";

contract RootKitEasyMoneyButton is TokensRecoverable
{
    IWETH immutable weth;
    KETH immutable keth;
    IERC20 immutable wbtc;
    RootKit immutable rootKit;
    
    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Pair immutable wethRootKit;
    IUniswapV2Pair immutable kethRootKit;
    IUniswapV2Pair immutable wbtcRootKit;
    IUniswapV2Pair immutable wethWbtc;

    uint256 constant smallestTrade = 0.5 ether;
    uint256 constant minProfit = 0.03 ether;

    constructor(RootKit _rootKit, IWETH _weth, KETH _keth, IERC20 _wbtc, IUniswapV2Router02 _uniswapV2Router)
    {
        rootKit = _rootKit;
        weth = _weth;
        keth = _keth;
        wbtc = _wbtc;

        uniswapV2Router = _uniswapV2Router;

        IUniswapV2Factory factory = IUniswapV2Factory(_uniswapV2Router.factory());

        wethRootKit = IUniswapV2Pair(UniswapV2Library.pairFor(address(factory), address(_weth), address(_rootKit)));
        kethRootKit = IUniswapV2Pair(UniswapV2Library.pairFor(address(factory), address(_keth), address(_rootKit)));
        wbtcRootKit = IUniswapV2Pair(UniswapV2Library.pairFor(address(factory), address(_wbtc), address(_rootKit)));
        wethWbtc = IUniswapV2Pair(UniswapV2Library.pairFor(address(factory), address(_weth), address(_wbtc)));

        _rootKit.approve(address(_uniswapV2Router), uint256(-1));
        _wbtc.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_uniswapV2Router), uint256(-1));
        _keth.approve(address(_uniswapV2Router), uint256(-1));
        _weth.approve(address(_keth), uint256(-1));
    }

    struct Balances
    {
        uint256 startingBalance;
        uint256 wethRootKit_Weth;
        uint256 wethRootKit_RootKit;
        uint256 kethRootKit_Keth;
        uint256 kethRootKit_RootKit;
        uint256 wbtcRootKit_Wbtc;
        uint256 wbtcRootKit_RootKit;
        uint256 wethWbtc_Weth;
        uint256 wethWbtc_Wbtc;
    }

    function getWeth(uint256 amount) private
    {
        uint256 balance = weth.balanceOf(address(this));
        if (balance < amount) { 
            keth.withdrawTokens(amount - balance);
        }
    }

    function getKeth(uint256 amount) private
    {
        uint256 balance = keth.balanceOf(address(this));
        if (balance < amount) { 
            keth.depositTokens(amount - balance);
        }
    }

    function wethRootKitKeth(Balances memory balances, uint256 amountIn) private pure returns (uint256 profit)
    {
        profit = amountIn * 997;
        profit = (profit * balances.wethRootKit_RootKit) / (balances.wethRootKit_Weth * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.kethRootKit_Keth) / (balances.kethRootKit_RootKit * 1000 + profit);
        return profit <= amountIn ? 0 : profit - amountIn;
    }

    function kethRootKitWeth(Balances memory balances, uint256 amountIn) private pure returns (uint256 profit)
    {
        profit = amountIn * 997;
        profit = (profit * balances.kethRootKit_RootKit) / (balances.kethRootKit_Keth * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wethRootKit_Weth) / (balances.wethRootKit_RootKit * 1000 + profit);
        return profit <= amountIn ? 0 : profit - amountIn;
    }

    function wethWbtcRootKitKeth(Balances memory balances, uint256 amountIn) private pure returns (uint256 profit)
    {
        profit = amountIn * 997;
        profit = (profit * balances.wethWbtc_Wbtc) / (balances.wethWbtc_Weth * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wbtcRootKit_RootKit) / (balances.wbtcRootKit_Wbtc * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.kethRootKit_Keth) / (balances.kethRootKit_RootKit * 1000 + profit);
        return profit <= amountIn ? 0 : profit - amountIn;
    }

    function kethRootKitWbtcWeth(Balances memory balances, uint256 amountIn) private pure returns (uint256 profit)
    {
        profit = amountIn * 997;
        profit = (profit * balances.kethRootKit_RootKit) / (balances.kethRootKit_Keth * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wbtcRootKit_Wbtc) / (balances.wbtcRootKit_RootKit * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wethRootKit_Weth) / (balances.wethRootKit_RootKit * 1000 + profit);
        return profit <= amountIn ? 0 : profit - amountIn;
    }

    function wethWbtcRootKitWeth(Balances memory balances, uint256 amountIn) private pure returns (uint256 profit)
    {
        profit = amountIn * 997;
        profit = (profit * balances.wethWbtc_Wbtc) / (balances.wethWbtc_Weth * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wbtcRootKit_RootKit) / (balances.wbtcRootKit_Wbtc * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wethRootKit_Weth) / (balances.wethRootKit_RootKit * 1000 + profit);
        return profit <= amountIn ? 0 : profit - amountIn;
    }

    function wethRootKitWbtcWeth(Balances memory balances, uint256 amountIn) private pure returns (uint256 profit)
    {
        profit = amountIn * 997;
        profit = (profit * balances.wethRootKit_RootKit) / (balances.wethRootKit_Weth * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wbtcRootKit_Wbtc) / (balances.wbtcRootKit_RootKit * 1000 + profit);
        profit *= 997;
        profit = (profit * balances.wethWbtc_Weth) / (balances.wethWbtc_Wbtc * 1000 + profit);
        return profit <= amountIn ? 0 : profit - amountIn;
    }

    function getBalances() private view returns (Balances memory balances)
    {
        uint256 r0;
        uint256 r1;
        balances.startingBalance = weth.balanceOf(address(this)) + keth.balanceOf(address(this));
        (r0, r1,) = wethRootKit.getReserves();
        (balances.wethRootKit_Weth, balances.wethRootKit_RootKit) = address(weth) < address(rootKit) ? (r0, r1) : (r1, r0);
        (r0, r1,) = kethRootKit.getReserves();
        (balances.kethRootKit_Keth, balances.kethRootKit_RootKit) = address(keth) < address(rootKit) ? (r0, r1) : (r1, r0);
        (r0, r1,) = wbtcRootKit.getReserves();
        (balances.wbtcRootKit_Wbtc, balances.wbtcRootKit_RootKit) = address(wbtc) < address(rootKit) ? (r0, r1) : (r1, r0);
        (r0, r1,) = wethWbtc.getReserves();
        (balances.wethWbtc_Weth, balances.wethWbtc_Wbtc) = address(weth) < address(wbtc) ? (r0, r1) : (r1, r0);
        return balances;
    }

    function getKethRootKitWethProfit(Balances memory balances) private pure returns (uint256 amountIn, uint256 profit)
    {
        uint256 maxProfit = 0;
        uint256 maxProfitAmountIn = 0;
        for (amountIn = smallestTrade; amountIn <= balances.startingBalance; amountIn *= 2) {            
            profit = kethRootKitWeth(balances, amountIn);
            if (profit <= maxProfit) { 
                break;
            }
            maxProfit = profit;
            maxProfitAmountIn = amountIn;
        }
        return maxProfit < minProfit ? (0, 0) : (maxProfitAmountIn, maxProfit);
    }

    function getWethRootKitKethProfit(Balances memory balances) private pure returns (uint256 amountIn, uint256 profit)
    {
        uint256 maxProfit = 0;
        uint256 maxProfitAmountIn = 0;
        for (amountIn = smallestTrade; amountIn <= balances.startingBalance; amountIn *= 2) {
            profit = wethRootKitKeth(balances, amountIn);
            if (profit <= maxProfit) { 
                break;
            }
            maxProfit = profit;
            maxProfitAmountIn = amountIn;
        }
        return maxProfit < minProfit ? (0, 0) : (maxProfitAmountIn, maxProfit);
    }

    function getWethWbtcRootKitKethProfit(Balances memory balances) private pure returns (uint256 amountIn, uint256 profit)
    {
        uint256 maxProfit = 0;
        uint256 maxProfitAmountIn = 0;
        for (amountIn = smallestTrade; amountIn <= balances.startingBalance; amountIn *= 2) {
            profit = wethWbtcRootKitKeth(balances, amountIn);
            if (profit <= maxProfit) { 
                break;
            }
            maxProfit = profit;
            maxProfitAmountIn = amountIn;
        }
        return maxProfit < minProfit ? (0, 0) : (maxProfitAmountIn, maxProfit);
    }

    function getKethRootKitWbtcWethProfit(Balances memory balances) private pure returns (uint256 amountIn, uint256 profit)
    {
        uint256 maxProfit = 0;
        uint256 maxProfitAmountIn = 0;
        for (amountIn = smallestTrade; amountIn <= balances.startingBalance; amountIn *= 2) {
            profit = kethRootKitWbtcWeth(balances, amountIn);
            if (profit <= maxProfit) { 
                break;
            }
            maxProfit = profit;
            maxProfitAmountIn = amountIn;
        }
        return maxProfit < minProfit ? (0, 0) : (maxProfitAmountIn, maxProfit);
    }

    function getWethWbtcRootKitWethProfit(Balances memory balances) private pure returns (uint256 amountIn, uint256 profit)
    {
        uint256 maxProfit = 0;
        uint256 maxProfitAmountIn = 0;
        for (amountIn = smallestTrade; amountIn <= balances.startingBalance; amountIn *= 2) {
            profit = wethWbtcRootKitWeth(balances, amountIn);
            if (profit <= maxProfit) { 
                break;
            }
            maxProfit = profit;
            maxProfitAmountIn = amountIn;
        }
        return maxProfit < minProfit ? (0, 0) : (maxProfitAmountIn, maxProfit);
    }

    function getWethRootKitWbtcWethProfit(Balances memory balances) private pure returns (uint256 amountIn, uint256 profit)
    {
        uint256 maxProfit = 0;
        uint256 maxProfitAmountIn = 0;
        for (amountIn = smallestTrade; amountIn <= balances.startingBalance; amountIn *= 2) {
            profit = wethRootKitWbtcWeth(balances, amountIn);
            if (profit <= maxProfit) { 
                break;
            }
            maxProfit = profit;
            maxProfitAmountIn = amountIn;
        }
        return maxProfit < minProfit ? (0, 0) : (maxProfitAmountIn, maxProfit);
    }

    function estimateProfit() public view returns (uint256 profit)
    {
        Balances memory balances = getBalances();

        (,profit) = getKethRootKitWethProfit(balances);
        if (profit > 0) { return profit; }
        (,profit) = getWethRootKitKethProfit(balances);
        if (profit > 0) { return profit; }
        (,profit) = getKethRootKitWbtcWethProfit(balances);
        if (profit > 0) { return profit; }
        (,profit) = getWethWbtcRootKitKethProfit(balances);
        if (profit > 0) { return profit; }
        (,profit) = getWethWbtcRootKitWethProfit(balances);
        if (profit > 0) { return profit; }
        (,profit) = getWethRootKitWbtcWethProfit(balances);
        return profit;
    }

    function gimmeMoney() public
    {
        Balances memory balances = getBalances(); 
        uint256 amountIn;

        (amountIn,) = getKethRootKitWethProfit(balances);
        if (amountIn > 0) {
            getKeth(amountIn);
            address[] memory path = new address[](3);
            path[0] = address(keth);
            path[1] = address(rootKit);
            path[2] = address(weth);
            uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
            return;
        }

        (amountIn,) = getWethRootKitKethProfit(balances);
        if (amountIn > 0) {
            getWeth(amountIn);
            address[] memory path = new address[](3);
            path[0] = address(weth);
            path[1] = address(rootKit);
            path[2] = address(keth);
            uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
            return;
        }

        (amountIn,) = getKethRootKitWbtcWethProfit(balances);
        if (amountIn > 0) {
            getKeth(amountIn);
            address[] memory path = new address[](4);
            path[0] = address(keth);
            path[1] = address(rootKit);
            path[2] = address(wbtc);
            path[3] = address(weth);
            uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
            return;
        }

        (amountIn,) = getWethWbtcRootKitKethProfit(balances);
        if (amountIn > 0) {
            getKeth(amountIn);
            address[] memory path = new address[](4);
            path[0] = address(weth);
            path[1] = address(wbtc);
            path[2] = address(rootKit);
            path[3] = address(keth);
            uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
            return;
        }

        (amountIn,) = getWethWbtcRootKitWethProfit(balances);
        if (amountIn > 0) {
            getKeth(amountIn);
            address[] memory path = new address[](4);
            path[0] = address(weth);
            path[1] = address(wbtc);
            path[2] = address(rootKit);
            path[3] = address(weth);
            uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
            return;
        }

        (amountIn,) = getWethRootKitWbtcWethProfit(balances);
        if (amountIn > 0) {
            getKeth(amountIn);
            address[] memory path = new address[](4);
            path[0] = address(weth);
            path[1] = address(rootKit);
            path[2] = address(wbtc);
            path[3] = address(weth);
            uniswapV2Router.swapExactTokensForTokens(amountIn, 0, path, address(this), block.timestamp);
            return;
        }
        
        revert("No profit");
    }
}
