// SPDX-License-Identifier: MIT

pragma solidity >=0.6.8;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../../interfaces/zTreasury/V2/IZTreasuryV2Metadata.sol';

contract zTreasuryV2Metadata is IZTreasuryV2Metadata {
  function isZTreasury() external override pure returns (bool) {
    return true;
  }
}
