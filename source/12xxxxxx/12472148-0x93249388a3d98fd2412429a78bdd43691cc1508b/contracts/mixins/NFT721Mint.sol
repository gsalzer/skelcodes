// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./OZ/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./NFT721Creator.sol";
import "./NFT721Market.sol";
import "./NFT721Metadata.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT721Mint is Initializable, ERC721Upgradeable, NFT721Creator, NFT721Market, NFT721Metadata {
  uint256 private nextTokenId;

  event Minted(
    address indexed creator,
    uint256 indexed tokenId,
    string indexed indexedTokenIPFSPath,
    string tokenIPFSPath
  );

  /**
   * @notice Gets the tokenId of the next NFT minted.
   */
  function getNextTokenId() public view returns (uint256) {
    return nextTokenId;
  }

  /**
   * @dev Called once after the initial deployment to set the initial tokenId.
   */
  function _initializeNFT721Mint() internal initializer {
    // Use ID 1 for the first NFT tokenId
    nextTokenId = 1;
  }

  /**
   * @notice Allows a creator to mint an NFT.
   */
  function mint(string memory tokenIPFSPath) public returns (uint256 tokenId) {
    tokenId = _mintToken(tokenIPFSPath);
  }

  /**
   * @notice Allows a creator to mint an NFT and set approval for the Foundation marketplace.
   * This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   */
  function mintAndApproveMarket(string memory tokenIPFSPath) public returns (uint256 tokenId) {
    tokenId = _mintToken(tokenIPFSPath);
    setApprovalForAll(getNFTMarket(), true);
  }

  function _mintToken(string memory tokenIPFSPath) private returns (uint256 tokenId) {
    tokenId = nextTokenId++;
    _mint(msg.sender, tokenId);
    _updateTokenCreator(tokenId, msg.sender);
    _setTokenIPFSPath(tokenId, tokenIPFSPath);
    emit Minted(msg.sender, tokenId, tokenIPFSPath, tokenIPFSPath);
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, NFT721Creator, NFT721Metadata) {
    super._burn(tokenId);
  }

  uint256[1000] private ______gap;
}

