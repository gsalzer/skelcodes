//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AbstractSweeperList.sol";

contract UserWallet {
  AbstractSweeperList sweeperList;
  constructor(AbstractSweeperList _sweeperlist) {
    sweeperList = _sweeperlist;
  }

  fallback () payable external { }
  receive () payable external { }

  function tokenFallback(address _from, uint _value, bytes memory _data) public pure {}

  function sweep(address _token, uint) public returns (bool) {
    (bool success, ) = sweeperList.sweeperOf(_token).delegatecall(msg.data);
    return success;
  }
}
