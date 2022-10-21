// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

import "../OpenZeppelin/IERC20.sol";

interface ISwapAdapter {
  function tokenToTokenExcess(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount,
    uint tokenOutAmount
  ) external view returns (address[] memory excessTokens, int[] memory excessAmounts);

  function ethToTokenExcess(
    IERC20 token,
    uint ethAmount,
    uint tokenAmount
  ) external view returns (address[] memory excessTokens, int[] memory excessAmounts);

  function tokenToEthExcess(
    IERC20 token,
    uint tokenAmount,
    uint ethAmount
  ) external view returns (address[] memory excessTokens, int[] memory excessAmounts);

  function tokenToTokenOutputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount
  ) external view returns (uint tokenOutAmount);

  function tokenToTokenInputAmount(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenOutAmount
  ) external view returns (uint tokenInAmount);

  function ethToTokenOutputAmount(
    IERC20 token,
    uint ethInAmount
  ) external view returns (uint tokenOutAmount);

  function ethToTokenInputAmount(
    IERC20 token,
    uint tokenOutAmount
  ) external view returns (uint ethInAmount);

  function tokenToEthOutputAmount(
    IERC20 token,
    uint tokenInAmount
  ) external view returns (uint ethOutAmount);

  function tokenToEthInputAmount(
    IERC20 token,
    uint ethOutAmount
  ) external view returns (uint tokenInAmount);

  function tokenToToken(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint tokenInAmount,
    uint tokenOutAmount,
    address account
  ) external;

  function ethToToken(
    IERC20 token,
    uint tokenAmount,
    address account
  ) external payable;

  function tokenToEth(
    IERC20 token,
    uint tokenAmount,
    uint ethAmount,
    address account
  ) external;
}

