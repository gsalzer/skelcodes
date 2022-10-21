pragma solidity 0.5.17;

import "./ERC721Basic.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @author Prashant Prabhakar Singh [prashantprabhakar123@gmail.com]
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}
