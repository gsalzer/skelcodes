// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import { TransferHelper } from "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract SwapRouterV1 {
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    event Swap(
        address indexed sender,
        address indexed token0,
        address indexed token1,
        uint256 amount0In,
        uint256 amount1Out
    );

    receive() external payable {}

    function swap(
        address handler,
        address token0,
        address token1,
        uint256 amount0In,
        uint256 minAmount1Out,
        address receiver,
        bytes calldata data
    ) external payable {
        if (token0 != address(0)) {
            TransferHelper.safeTransferFrom(token0, msg.sender, handler, amount0In);
        }

        (bool success, bytes memory res) = handler.call{ value: msg.value }(data);

        assembly {
            if eq(success, 0) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        uint256 balance = _getBalance(token1, address(this));
        require(balance >= minAmount1Out, "STE");

        _transfer(token1, receiver, balance);
    }

    function _getBalance(address token, address account) internal view returns (uint256) {
        if (token == address(0)) return account.balance;
        return IERC20(token).balanceOf(account);
    }

    function _transfer(
        address token,
        address to,
        uint256 value
    ) internal {
        if (token == address(0)) return TransferHelper.safeTransferETH(to, value);
        return TransferHelper.safeTransfer(token, to, value);
    }
}

