//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface IEvilTeddyBear is IERC721Enumerable {
    function mint(address) external;
}

