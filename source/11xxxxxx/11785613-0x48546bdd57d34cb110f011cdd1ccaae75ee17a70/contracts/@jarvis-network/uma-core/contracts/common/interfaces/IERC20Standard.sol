// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC20Standard is IERC20 {
  function decimals() external view returns (uint8);
}

