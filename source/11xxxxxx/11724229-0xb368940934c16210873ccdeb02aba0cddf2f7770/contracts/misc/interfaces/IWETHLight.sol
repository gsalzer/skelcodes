
// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';

interface IWETH is IERC20 {
  function deposit() external payable;
  function withdraw(uint wad) external;
}
