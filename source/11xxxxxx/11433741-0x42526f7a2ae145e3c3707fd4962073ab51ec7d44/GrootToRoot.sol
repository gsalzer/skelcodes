// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./TokensRecoverable.sol";
import "./RootKit.sol";
import "./GrootKit.sol";
import "./IUniswapV2Router02.sol";
import "./IWETH.sol";

contract GrootToRoot is TokensRecoverable
{
    RootKit immutable rootKit;
    GrootKit immutable grootKit;
    IUniswapV2Router02 immutable uniswapV2Router;
    IWETH immutable weth;
    address immutable public vault;

    constructor(RootKit _rootKit, GrootKit _grootKit, IUniswapV2Router02 _uniswapV2Router, address _vault)
    {
        rootKit = _rootKit;
        grootKit = _grootKit;
        uniswapV2Router = _uniswapV2Router;
        vault = _vault;

        weth = IWETH(_uniswapV2Router.WETH());

        _grootKit.approve(address(_uniswapV2Router), uint256(-1));
    }

    function buyRoot() public
    {
        require (msg.sender == tx.origin, "Please select all images with a bicycle");
        uint256 balance = grootKit.balanceOf(address(this));
        require (balance > 0, "No groot to sell");

        address[] memory path = new address[](3);
        path[0] = address(grootKit);
        path[1] = address(weth);
        path[2] = address(rootKit);
        uniswapV2Router.swapExactTokensForTokens(balance, 0, path, vault, block.timestamp);
    }
}
