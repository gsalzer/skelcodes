// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC998ERC721BottomUp {
    event TransferToParent(
        address indexed _toContract,
        uint256 indexed _toTokenId,
        uint256 _tokenId
    );
    event TransferFromParent(
        address indexed _fromContract,
        uint256 indexed _fromTokenId,
        uint256 _tokenId
    );

    function rootOwnerOf(uint256 _tokenId)
        external
        view
        returns (bytes32 rootOwner);

    /**
     * The tokenOwnerOf function gets the owner of the _tokenId which can be a user address or another ERC721 token.
     * The tokenOwner address return value can be either a user address or an ERC721 contract address.
     * If the tokenOwner address is a user address then parentTokenId will be 0 and should not be used or considered.
     * If tokenOwner address is a user address then isParent is false, otherwise isChild is true, which means that
     * tokenOwner is an ERC721 contract address and _tokenId is a child of tokenOwner and parentTokenId.
     */
    function tokenOwnerOf(uint256 _tokenId)
        external
        view
        returns (
            bytes32 tokenOwner,
            uint256 parentTokenId,
            bool isParent
        );

    // Transfers _tokenId as a child to _toContract and _toTokenId
    function transferToParent(
        address _from,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    // Transfers _tokenId from a parent ERC721 token to a user address.
    function transferFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) external;

    // Transfers _tokenId from a parent ERC721 token to a parent ERC721 token.
    function transferAsChild(
        address _fromContract,
        uint256 _fromTokenId,
        address _toContract,
        uint256 _toTokenId,
        uint256 _tokenId,
        bytes memory _data
    ) external;
}

