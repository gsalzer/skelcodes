//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractSweeper.sol";

abstract contract AbstractSweeperList {
  function sweeperOf(address _token) public virtual returns (address);
}
