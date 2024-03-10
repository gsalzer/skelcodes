/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../../0xerc1155/interfaces/IERC20.sol';

interface IERC20WowsMintable is IERC20 {
  function mint(address account, uint256 amount) external returns (bool);

  function enableUniV2Pair(bool enable) external;
}

