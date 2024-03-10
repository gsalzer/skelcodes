// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Events721 {
    event DepositedErc721IntoEgg(
        uint256 eggId,
        address indexed owner,
        address indexed erc721Token,
        uint256 tokenId
    );

    event WithdrewErc721FromEgg(
        uint256 eggId,
        address indexed owner,
        address indexed erc721Token,
        uint256 tokenId,
        address indexed to
    );

    event SentErc721(
        uint256 fromEggId,
        address indexed owner,
        address indexed erc721Token,
        uint256 tokenId,
        uint256 toEggId
    );

    event SwapedErc721(
        address indexed owner,
        uint256 eggId,
        address inToken,
        uint256 inId,
        address outToken,
        address indexed to
    );
}
