//SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface IOrcs is IERC721Enumerable {
    function mint(address) external;
}

