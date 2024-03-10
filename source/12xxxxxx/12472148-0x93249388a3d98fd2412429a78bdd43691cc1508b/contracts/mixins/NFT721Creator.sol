// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./OZ/ERC721Upgradeable.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
abstract contract NFT721Creator is Initializable, ERC721Upgradeable {
  mapping(uint256 => address payable) private tokenIdToCreator;

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);

  /*
   * bytes4(keccak256('tokenCreator(uint256)')) == 0x40c1a064
   */
  bytes4 private constant _INTERFACE_TOKEN_CREATOR = 0x40c1a064;

  modifier onlyCreator(uint256 tokenId) {
    require(tokenIdToCreator[tokenId] == msg.sender, "NFT721Creator: Caller is not creator");
    _;
  }

  modifier onlyCreatorAndOwner(uint256 tokenId) {
    require(tokenIdToCreator[tokenId] == msg.sender, "NFT721Creator: Caller is not creator");
    require(ownerOf(tokenId) == msg.sender, "NFT721Creator: Caller does not own the NFT");
    _;
  }

  /**
   * @dev Called once after the initial deployment to register the interface with ERC165.
   */
  function _initializeNFT721Creator() internal initializer {
    _registerInterface(_INTERFACE_TOKEN_CREATOR);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   */
  function tokenCreator(uint256 tokenId) public view returns (address payable) {
    return tokenIdToCreator[tokenId];
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burn(uint256 tokenId) public onlyCreatorAndOwner(tokenId) {
    _burn(tokenId);
  }

  /**
   * @dev Remove the creator record when burned.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete tokenIdToCreator[tokenId];

    super._burn(tokenId);
  }

  uint256[1000] private ______gap;
}

