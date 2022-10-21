// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Panthers {
    function balanceOf(address owner) public view virtual returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256);
}

