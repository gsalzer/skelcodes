// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./NFT721Core.sol";
import "./NFT721Creator.sol";

/**
 * @notice A mixin to extend the OpenZeppelin metadata implementation.
 */
abstract contract NFT721Metadata is NFT721Creator {
  using StringsUpgradeable for uint256;

  /**
   * @dev Stores hashes minted by a creator to prevent duplicates.
   */
  mapping(address => mapping(string => bool)) private creatorToIPFSHashToMinted;

  event BaseURIUpdated(string baseURI);
  event TokenIPFSPathUpdated(uint256 indexed tokenId, string indexed indexedTokenIPFSPath, string tokenIPFSPath);
  // This event was used in an order version of the contract
  event NFTMetadataUpdated(string name, string symbol, string baseURI);

  /**
   * @notice Returns the IPFSPath to the metadata JSON file for a given NFT.
   */
  function getTokenIPFSPath(uint256 tokenId) public view returns (string memory) {
    return _tokenURIs[tokenId];
  }

  /**
   * @notice Checks if the creator has already minted a given NFT.
   */
  function getHasCreatorMintedIPFSHash(address creator, string memory tokenIPFSPath) public view returns (bool) {
    return creatorToIPFSHashToMinted[creator][tokenIPFSPath];
  }

  function _updateBaseURI(string memory _baseURI) internal {
    _setBaseURI(_baseURI);

    emit BaseURIUpdated(_baseURI);
  }

  /**
   * @dev The IPFS path should be the CID + file.extension, e.g.
   * `QmfPsfGwLhiJrU8t9HpG4wuyjgPo9bk8go4aQqSu9Qg4h7/metadata.json`
   */
  function _setTokenIPFSPath(uint256 tokenId, string memory _tokenIPFSPath) internal {
    // 46 is the minimum length for an IPFS content hash, it may be longer if paths are used
    require(bytes(_tokenIPFSPath).length >= 46, "NFT721Metadata: Invalid IPFS path");
    require(!creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath], "NFT721Metadata: NFT was already minted");

    creatorToIPFSHashToMinted[msg.sender][_tokenIPFSPath] = true;
    _setTokenURI(tokenId, _tokenIPFSPath);
  }

  /**
   * @dev When a token is burned, remove record of it allowing that creator to re-mint the same NFT again in the future.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete creatorToIPFSHashToMinted[msg.sender][_tokenURIs[tokenId]];
    super._burn(tokenId);
  }

  uint256[999] private ______gap;
}

