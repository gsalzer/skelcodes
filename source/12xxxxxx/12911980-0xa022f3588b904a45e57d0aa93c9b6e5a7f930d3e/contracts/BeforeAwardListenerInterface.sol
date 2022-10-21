// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "@openzeppelin/contracts-upgradeable/introspection/IERC165Upgradeable.sol";

interface BeforeAwardListenerInterface is IERC165Upgradeable {
  function beforePrizePoolAwarded(uint256 randomNumber, uint256 prizePeriodStartedAt) external;
}

