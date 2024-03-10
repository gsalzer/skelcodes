// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStakingPool is IERC20 {
  function distributeRewards (uint amount) external;
}

