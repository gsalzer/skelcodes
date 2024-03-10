pragma solidity 0.5.17;

import "./ERC721Basic.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata 
 * @author Prashant Prabhakar Singh [prashantprabhakar123@gmail.com]
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string memory);
}
