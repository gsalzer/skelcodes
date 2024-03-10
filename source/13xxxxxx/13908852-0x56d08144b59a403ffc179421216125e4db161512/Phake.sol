// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Phake {
    function balanceOf(address owner) public view virtual returns (uint256);
}

