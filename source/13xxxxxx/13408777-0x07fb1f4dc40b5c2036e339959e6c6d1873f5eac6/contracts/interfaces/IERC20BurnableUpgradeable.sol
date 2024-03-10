// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface IERC20BurnableUpgradeable is IERC20Upgradeable {
  function burn(uint256 amount) external;
}

