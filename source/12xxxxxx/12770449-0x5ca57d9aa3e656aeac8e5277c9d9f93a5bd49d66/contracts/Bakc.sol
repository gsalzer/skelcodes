// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

abstract contract Bakc {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

