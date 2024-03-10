// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:

This is a money button

Press it for free money

and LOL cus it actually works

*/

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./KETH.sol";
import "./IWETH.sol";
import "./UniswapV2Library.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract RootKitMoneyButton is TokensRecoverable
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IUniswapV2Router02 immutable uniswapV2Router;
    IUniswapV2Factory immutable uniswapV2Factory;
    KETH immutable keth;
    IWETH immutable weth;
    mapping (address => bool) approved;

    address public vault;
    uint16 public percentToVault; // 10000 = 100%;

    constructor(IUniswapV2Router02 _uniswapV2Router, KETH _keth)
    {
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
        keth = _keth;
        IWETH _weth = weth = IWETH(address(_keth.wrappedToken()));

        _weth.approve(address(_keth), uint256(-1));
    }

    receive() external payable
    {
        require (msg.sender == address(weth) || msg.sender == address(keth));
    }

    function configure(address _vault, uint16 _percentToVault) public ownerOnly() {
        require (_vault != address(0) && _percentToVault <= 10000);
        vault = _vault;
        percentToVault = _percentToVault;
    }

    function estimateProfit(address[] calldata _fullPath, uint256 _amountIn) public view returns (uint256)
    {
        uint256 amountOut = _amountIn;
        address[] memory path = new address[](2);
        for (uint256 x=1; x<=_fullPath.length; ++x) {
            path[0] = _fullPath[x-1];
            path[1] = _fullPath[x%_fullPath.length];
            bool kindaEthIn = path[0] == address(0) || path[0] == address(weth) || path[0] == address(keth);
            bool kindaEthOut = path[1] == address(0) || path[1] == address(weth) || path[1] == address(keth);
            if (kindaEthIn && kindaEthOut) { continue; }
            (uint256[] memory amountsOut) = UniswapV2Library.getAmountsOut(address(uniswapV2Factory), amountOut, path);
            amountOut = amountsOut[1];
        }
        if (amountOut <= _amountIn) { return 0; }
        return amountOut - _amountIn;
    }

    function gimmeMoney(address[] calldata _fullPath, uint256 _amountIn, uint256 _minProfit) public payable
    {
        require ((msg.value == 0) != (_fullPath[0] == address(0)), "Send ETH if and only if the path starts with ETH");
        uint256 amountOut = _amountIn;
        address[] memory path = new address[](2);
        uint256 count = _fullPath.length;
        if (_fullPath[0] != address(0)) {
            IERC20(_fullPath[0]).safeTransferFrom(msg.sender, address(this), _amountIn);
        }
        for (uint256 x=1; x<=count; ++x) {
            address tokenIn = _fullPath[x-1];
            address tokenOut = _fullPath[x%count];
            if (tokenIn == tokenOut) { continue; }
            if (tokenIn == address(0)) {
                require (x == 1, "Conversion from ETH can only happen first");
                amountOut = _amountIn = msg.value;
                if (tokenOut == address(weth)) {
                    weth.deposit{ value: amountOut }();
                }
                else if (tokenOut == address(keth)) {
                    keth.deposit{ value: amountOut }();
                }
                else {
                    revert("ETH must convert to WETH or KETH");
                }
                continue;
            }
            if (tokenOut == address(0)) {
                require (x == _fullPath.length, "Conversion to ETH can only happen last");
                if (tokenIn == address(weth)) {
                    weth.withdraw(amountOut);
                }
                else if (tokenIn == address(keth)) {
                    keth.withdraw(amountOut);
                }
                else {
                    revert("ETH must be converted from WETH or KETH");
                }
                continue;
            }
            if (tokenIn == address(weth) && tokenOut == address(keth)) {
                keth.depositTokens(amountOut);
                continue;
            }
            if (tokenIn == address(keth) && tokenOut == address(weth)) {
                keth.withdrawTokens(amountOut);
                continue;
            }            
            if (!approved[tokenIn]) {
                IERC20(tokenIn).safeApprove(address(uniswapV2Router), uint256(-1));
                approved[tokenIn] = true;
            }
            path[0] = tokenIn;
            path[1] = tokenOut;
            (uint256[] memory amounts) = uniswapV2Router.swapExactTokensForTokens(amountOut, 0, path, address(this), block.timestamp);
            amountOut = amounts[1];
        }

        amountOut = _fullPath[0] == address(0) ? address(this).balance : IERC20(_fullPath[0]).balanceOf(address(this));

        require (amountOut >= _amountIn.add(_minProfit), "Not enough profit");

        uint256 forVault = (amountOut - _amountIn).mul(percentToVault) / 10000;
        if (_fullPath[0] == address(0)) {
            (bool success,) = msg.sender.call{ value: amountOut - forVault }("");
            require (success, "Transfer failed");
            (success,) = vault.call{ value: forVault }("");
            require (success, "Transfer failed");
            return;
        }
        IERC20(_fullPath[0]).safeTransfer(msg.sender, amountOut - forVault);
        IERC20(_fullPath[0]).safeTransfer(vault, forVault);
    }
}
