// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "./ERC165.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) external view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) external view returns (address _owner);

  function approve(address _to, uint256 _tokenId) external;
  function getApproved(uint256 _tokenId) external view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) external;
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) external;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Enumerable is ERC721Basic {
  function totalSupply() external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) external view returns (uint256);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721Metadata is ERC721Basic {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
interface ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata, ERC165 {}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
interface ERC721Receiver {
  function onERC721Received(address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

