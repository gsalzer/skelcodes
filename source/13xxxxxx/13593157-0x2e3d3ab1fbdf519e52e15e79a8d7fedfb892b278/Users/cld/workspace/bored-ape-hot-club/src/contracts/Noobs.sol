// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Noobs {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function listNoobsForOwner(address _owner) external view virtual returns(uint256[] memory );
}

