// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICeramic {
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function totalSupply() external view returns (uint256);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory);
}

