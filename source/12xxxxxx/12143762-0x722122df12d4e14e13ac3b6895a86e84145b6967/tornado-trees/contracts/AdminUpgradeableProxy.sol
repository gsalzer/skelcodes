// https://tornado.cash
/*
* d888888P                                           dP              a88888b.                   dP
*    88                                              88             d8'   `88                   88
*    88    .d8888b. 88d888b. 88d888b. .d8888b. .d888b88 .d8888b.    88        .d8888b. .d8888b. 88d888b.
*    88    88'  `88 88'  `88 88'  `88 88'  `88 88'  `88 88'  `88    88        88'  `88 Y8ooooo. 88'  `88
*    88    88.  .88 88       88    88 88.  .88 88.  .88 88.  .88 dP Y8.   .88 88.  .88       88 88    88
*    dP    `88888P' dP       dP    dP `88888P8 `88888P8 `88888P' 88  Y88888P' `88888P8 `88888P' dP    dP
* ooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";

/**
 * @dev TransparentUpgradeableProxy where admin is allowed to call implementation methods.
 */
contract AdminUpgradeableProxy is TransparentUpgradeableProxy {
  /**
   * @dev Initializes an upgradeable proxy backed by the implementation at `_logic`.
   */
  constructor(
    address _logic,
    address _admin,
    bytes memory _data
  ) public payable TransparentUpgradeableProxy(_logic, _admin, _data) {}

  /**
   * @dev Override to allow admin access the fallback function.
   */
  function _beforeFallback() internal override {}
}

