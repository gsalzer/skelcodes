pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMintableCollection is IERC721 {
    function burn(uint256 tokenId) external;
    function mint(address to, uint256 tokenId) external;
}

