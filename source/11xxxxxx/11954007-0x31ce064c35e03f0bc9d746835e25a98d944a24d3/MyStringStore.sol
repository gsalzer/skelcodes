pragma solidity 0.7.2;

// SPDX-License-Identifier: UNLICENSED

contract MyStringStore {
  string public myString = "Hello World";

  function set(string memory x) public {
    myString = x;
  }
}
