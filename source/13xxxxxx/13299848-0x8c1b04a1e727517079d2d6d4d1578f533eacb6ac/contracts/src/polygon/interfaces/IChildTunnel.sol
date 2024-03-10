/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

/**
 * @title ICChildTunnel
 */
interface IChildTunnel {
  // distribute internal rewards on root chain
  function distribute(uint256 amount) external;
}

