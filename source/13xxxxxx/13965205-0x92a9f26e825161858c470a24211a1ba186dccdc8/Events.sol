// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Events {
    event LockedEgg(
        uint256 eggId,
        address indexed owner,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    event OpenedEgg(
        uint256 eggId,
        address indexed owner
    );

    event ClosedEgg(
        uint256 eggId,
        address indexed owner
    );

    event DepositedErc20IntoEgg(
        uint256 eggId,
        address indexed owner,
        address indexed erc20Token,
        uint256 amount
    );

    event WithdrewErc20FromEgg(
        uint256 eggId,
        address indexed owner,
        address indexed erc20Token,
        uint256 amount,
        address indexed to
    );

    event SentErc20(
        uint256 fromEggId,
        address indexed owner,
        address indexed erc20Token,
        uint256 amount,
        uint256 toEggId
    );

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

    event DepositedErc1155IntoEgg(
        uint256 eggId,
        address indexed owner,
        address indexed erc1155Token,
        uint256 tokenId,
        uint256 amount
    );

    event WithdrewErc1155FromEgg(
        uint256 eggId,
        address indexed owner,
        address indexed erc1155Token,
        uint256 tokenId,
        uint256 amount,
        address indexed to
    );

    event SentErc1155(
        uint256 fromEggId,
        address indexed owner,
        address indexed erc1155Token,
        uint256 tokenId,
        uint256 amount,
        uint256 toEggId
    );

    event SwapedErc20(
        address indexed owner,
        uint256 eggId,
        address inToken,
        uint256 inAmount,
        address outToken,
        address indexed to
    );

    event SwapedErc721(
        address indexed owner,
        uint256 eggId,
        address inToken,
        uint256 inId,
        address outToken,
        address indexed to
    );

    event SwapedErc1155(
        address indexed owner,
        uint256 eggId,
        address inToken,
        uint256 inId,
        uint256 inAmount,
        address outToken,
        uint256 outId,
        address indexed to
    );
}
