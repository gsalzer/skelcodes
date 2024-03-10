// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import '../token/IERC20.sol';
import '../access/Withdrawable.sol';

/// @title Brink OneInchAdapter
/// @notice Deployed once and used by Brink executors to fulfill swaps. Uses AggregationRouterV4 from 1inch.
contract OneInchAdapter is Withdrawable {

  /// @dev Contract Address of the 1inch AggregationRouterV4
  address constant AGG_ROUTER_V4 = 0x1111111254fb6c44bAC0beD2854e76F90643097d;

  /// @dev Max uint
  uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

  /// @dev Ethereum address representations
  IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
  IERC20 private constant _ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);

  /// @dev Makes a call to AggregationRouterV4 with swap byte data
  /// @dev returns the requested tokenOutAmount to Account and keeps the rest.
  /// @param data swap byte data for AggregationRouterV4
  /// @param tokenIn Address of the token to be swapped
  /// @param tokenInAmount Token amount deposited
  /// @param tokenOut Address of the token to be returned from the swap
  /// @param tokenOutAmount Token amount deposited
  /// @param account Address of the account to receive the tokenOut
  function oneInchSwap(bytes memory data, IERC20 tokenIn, uint tokenInAmount, IERC20 tokenOut, uint tokenOutAmount, address payable account) external payable {
    if (!isETH(tokenIn)) {
      if (tokenIn.allowance(address(this), AGG_ROUTER_V4) < tokenInAmount) {
        tokenIn.approve(AGG_ROUTER_V4, MAX_INT);
      }
    }

    assembly {
      let result := call(gas(), AGG_ROUTER_V4, callvalue(), add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
    }

    if (!isETH(tokenOut)) {
      tokenOut.transfer(account, tokenOutAmount);
    } else {
      account.transfer(tokenOutAmount);
    }
  }

  /// @dev Checks if IERC20 token address is an ETH representation
  /// @param token address of a token
  function isETH(IERC20 token) internal pure returns (bool) {
    return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
  }

  receive() external payable { }
}
