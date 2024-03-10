// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IDropKitCollection is
    IERC721Upgradeable,
    IERC721EnumerableUpgradeable
{
    /**
     * @dev Contract upgradeable initializer
     */
    function initialize(string memory, string memory, address) external;

    /**
     * @dev part of Ownable
     */
    function transferOwnership(address) external;
}

