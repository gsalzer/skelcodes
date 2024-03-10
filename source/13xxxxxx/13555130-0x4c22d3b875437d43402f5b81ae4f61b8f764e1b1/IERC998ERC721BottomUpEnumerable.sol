// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC998ERC721BottomUpEnumerable {
    function totalChildTokens(address _parentContract, uint256 _parentTokenId)
        external
        view
        returns (uint256);

    function childTokenByIndex(
        address _parentContract,
        uint256 _parentTokenId,
        uint256 _index
    ) external view returns (uint256);
}

