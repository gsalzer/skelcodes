/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Booster is Ownable {
  using SafeERC20 for IERC20;

  constructor(address _owner) {
    transferOwnership(_owner);
  }

  // Dummy booster implementation, send token to next implementation
  function transferTo(address _token, address _recipient) external onlyOwner {
    require(_recipient != address(0), 'burn not allowed');
    IERC20(_token).safeTransfer(
      _recipient,
      IERC20(_token).balanceOf(address(this))
    );
  }
}

