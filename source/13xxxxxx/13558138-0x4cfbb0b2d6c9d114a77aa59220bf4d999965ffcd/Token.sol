//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Token {
  function balanceOf(address) public virtual returns (uint);
  function transfer(address, uint) public virtual returns (bool);
}
