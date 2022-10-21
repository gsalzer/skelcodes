// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IERC1155Mintable is IERC1155Upgradeable {
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount,
        string calldata uri,
        bytes memory data
    ) external;
}
