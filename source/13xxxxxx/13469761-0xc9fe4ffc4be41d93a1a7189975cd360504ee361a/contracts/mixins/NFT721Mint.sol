// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "./OZ/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import "./NFT721Creator.sol";
import "./NFT721Market.sol";
import "./NFT721Metadata.sol";
import "./NFT721ProxyCall.sol";

/**
 * @notice Allows creators to mint NFTs.
 */
abstract contract NFT721Mint is
  Initializable,
  ERC721Upgradeable,
  NFT721ProxyCall,
  NFT721Creator,
  NFT721Market,
  NFT721Metadata
{
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
    tokenId = nextTokenId++;
    _mint(msg.sender, tokenId);
    _updateTokenCreator(tokenId, msg.sender);
    _setTokenIPFSPath(tokenId, tokenIPFSPath);
    emit Minted(msg.sender, tokenId, tokenIPFSPath, tokenIPFSPath);
  }

  /**
   * @notice Allows a creator to mint an NFT and set approval for the Foundation marketplace.
   * This can be used by creators the first time they mint an NFT to save having to issue a separate
   * approval transaction before starting an auction.
   */
  function mintAndApproveMarket(string memory tokenIPFSPath) public returns (uint256 tokenId) {
    tokenId = mint(tokenIPFSPath);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
   */
  function mintWithCreatorPaymentAddress(string memory tokenIPFSPath, address payable tokenCreatorPaymentAddress)
    public
    returns (uint256 tokenId)
  {
    require(tokenCreatorPaymentAddress != address(0), "NFT721Mint: tokenCreatorPaymentAddress is required");
    tokenId = mint(tokenIPFSPath);
    _setTokenCreatorPaymentAddress(tokenId, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address.
   * Also sets approval for the Foundation marketplace.  This can be used by creators the first time they mint an NFT to
   * save having to issue a separate approval transaction before starting an auction.
   */
  function mintWithCreatorPaymentAddressAndApproveMarket(
    string memory tokenIPFSPath,
    address payable tokenCreatorPaymentAddress
  ) public returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, tokenCreatorPaymentAddress);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   */
  function mintWithCreatorPaymentFactory(
    string memory tokenIPFSPath,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData
  ) public returns (uint256 tokenId) {
    address payable tokenCreatorPaymentAddress = _proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );
    tokenId = mintWithCreatorPaymentAddress(tokenIPFSPath, tokenCreatorPaymentAddress);
  }

  /**
   * @notice Allows a creator to mint an NFT and have creator revenue/royalties sent to an alternate address
   * which is defined by a contract call, typically a proxy contract address representing the payment terms.
   * Also sets approval for the Foundation marketplace.  This can be used by creators the first time they mint an NFT to
   * save having to issue a separate approval transaction before starting an auction.
   */
  function mintWithCreatorPaymentFactoryAndApproveMarket(
    string memory tokenIPFSPath,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData
  ) public returns (uint256 tokenId) {
    tokenId = mintWithCreatorPaymentFactory(tokenIPFSPath, paymentAddressFactory, paymentAddressCallData);
    setApprovalForAll(getNFTMarket(), true);
  }

  /**
   * @dev Explicit override to address compile errors.
   */
  function _burn(uint256 tokenId) internal virtual override(ERC721Upgradeable, NFT721Creator, NFT721Metadata) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721Upgradeable, NFT721Creator, NFT721Market)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  uint256[1000] private ______gap;
}

