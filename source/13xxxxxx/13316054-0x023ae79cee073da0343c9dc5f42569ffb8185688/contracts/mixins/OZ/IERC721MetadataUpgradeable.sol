// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * From https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.4.0/contracts/token/ERC721
 * Modified in order to:
 *  - Only include metadata functions
 */

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

