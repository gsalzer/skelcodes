//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721EnumerableUpgradeable.sol";

interface ISupremePizzas is IERC721EnumerableUpgradeable {
    function mint(address) external;
}
