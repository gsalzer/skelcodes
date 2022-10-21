//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract ICNP is Ownable, IERC721 {
    function ownerOf(uint256 tokenId) public view virtual override returns (address);
    function balanceOf(address owner) public view virtual override returns (uint256);
}
