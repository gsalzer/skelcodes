// SPDX-License-Identifier: BUSDL-1.1
pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import {SafeERC20} from "contracts/libraries/Imports.sol";
import {IERC20, IAssetAllocation} from "contracts/common/Imports.sol";
import {IUniswapV2Router02} from "../Sushiswap.sol";
import {ISwap} from "contracts/lpaccount/Imports.sol";

abstract contract SwapBase is ISwap {
    using SafeERC20 for IERC20;

    IUniswapV2Router02 private constant _ROUTER =
        IUniswapV2Router02(0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F);

    IERC20 internal immutable _IN_TOKEN;
    IERC20 internal immutable _OUT_TOKEN;

    event Swap(
        uint256 amount,
        uint256 minAmount,
        address[] path,
        uint256 deadline,
        uint256 amountOut
    );

    constructor(IERC20 inToken, IERC20 outToken) public {
        _IN_TOKEN = inToken;
        _OUT_TOKEN = outToken;
    }

    // TODO: create function for calculating min amount
    function swap(uint256 amount, uint256 minAmount) external override {
        _IN_TOKEN.safeApprove(address(_ROUTER), 0);
        _IN_TOKEN.safeApprove(address(_ROUTER), amount);

        address[] memory path = _getPath();

        // solhint-disable-next-line not-rely-on-time
        uint256 deadline = block.timestamp;

        uint256[] memory amounts =
            _ROUTER.swapExactTokensForTokens(
                amount,
                minAmount,
                path,
                address(this),
                deadline
            );

        uint256 amountOut = amounts[amounts.length - 1];

        emit Swap(amount, minAmount, path, deadline, amountOut);
    }

    function erc20Allocations()
        external
        view
        override
        returns (IERC20[] memory)
    {
        IERC20[] memory allocations = new IERC20[](2);
        allocations[0] = _IN_TOKEN;
        allocations[1] = _OUT_TOKEN;
        return allocations;
    }

    function _getPath() internal view virtual returns (address[] memory);
}

