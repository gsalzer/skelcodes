// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

interface ISynapseBridge {
  using SafeERC20 for IERC20;

  function deposit(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount
  ) external;

  function depositAndSwap(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 minDy,
    uint256 deadline
  ) external;
}

