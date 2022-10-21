// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./OZ/ERC721Upgradeable.sol";
import "./AccountMigration.sol";
import "../libraries/BytesLibrary.sol";
import "./NFT721ProxyCall.sol";
import "../interfaces/ITokenCreator.sol";
import "../interfaces/ITokenCreatorPaymentAddress.sol";

/**
 * @notice Allows each token to be associated with a creator.
 */
abstract contract NFT721Creator is
  Initializable,
  AccountMigration,
  ERC721Upgradeable,
  ITokenCreator,
  ITokenCreatorPaymentAddress,
  NFT721ProxyCall
{
  using BytesLibrary for bytes;

  mapping(uint256 => address payable) private tokenIdToCreator;

  /**
   * @dev Stores an optional alternate address to receive creator revenue and royalty payments.
   */
  mapping(uint256 => address payable) private tokenIdToCreatorPaymentAddress;

  event TokenCreatorUpdated(address indexed fromCreator, address indexed toCreator, uint256 indexed tokenId);
  event TokenCreatorPaymentAddressSet(
    address indexed fromPaymentAddress,
    address indexed toPaymentAddress,
    uint256 indexed tokenId
  );
  event NFTCreatorMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event NFTOwnerMigrated(uint256 indexed tokenId, address indexed originalAddress, address indexed newAddress);
  event PaymentAddressMigrated(
    uint256 indexed tokenId,
    address indexed originalAddress,
    address indexed newAddress,
    address originalPaymentAddress,
    address newPaymentAddress
  );

  modifier onlyCreatorAndOwner(uint256 tokenId) {
    require(tokenIdToCreator[tokenId] == msg.sender, "NFT721Creator: Caller is not creator");
    require(ownerOf(tokenId) == msg.sender, "NFT721Creator: Caller does not own the NFT");
    _;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    if (
      interfaceId == type(ITokenCreator).interfaceId || interfaceId == type(ITokenCreatorPaymentAddress).interfaceId
    ) {
      return true;
    }
    return super.supportsInterface(interfaceId);
  }

  /**
   * @notice Returns the creator's address for a given tokenId.
   */
  function tokenCreator(uint256 tokenId) public view override returns (address payable) {
    return tokenIdToCreator[tokenId];
  }

  /**
   * @notice Returns the payment address for a given tokenId.
   * @dev If an alternate address was not defined, the creator is returned instead.
   */
  function getTokenCreatorPaymentAddress(uint256 tokenId)
    public
    view
    override
    returns (address payable tokenCreatorPaymentAddress)
  {
    tokenCreatorPaymentAddress = tokenIdToCreatorPaymentAddress[tokenId];
    if (tokenCreatorPaymentAddress == address(0)) {
      tokenCreatorPaymentAddress = tokenIdToCreator[tokenId];
    }
  }

  function _updateTokenCreator(uint256 tokenId, address payable creator) internal {
    emit TokenCreatorUpdated(tokenIdToCreator[tokenId], creator, tokenId);

    tokenIdToCreator[tokenId] = creator;
  }

  /**
   * @dev Allow setting a different address to send payments to for both primary sale revenue
   * and secondary sales royalties.
   */
  function _setTokenCreatorPaymentAddress(uint256 tokenId, address payable tokenCreatorPaymentAddress) internal {
    emit TokenCreatorPaymentAddressSet(tokenIdToCreatorPaymentAddress[tokenId], tokenCreatorPaymentAddress, tokenId);
    tokenIdToCreatorPaymentAddress[tokenId] = tokenCreatorPaymentAddress;
  }

  /**
   * @notice Allows the creator to burn if they currently own the NFT.
   */
  function burn(uint256 tokenId) public onlyCreatorAndOwner(tokenId) {
    _burn(tokenId);
  }

  /**
   * @notice Allows an NFT owner or creator and Foundation to work together in order to update the creator
   * to a new account and/or transfer NFTs to that account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   * @dev This will gracefully skip any NFTs that have been burned or transferred.
   */
  function adminAccountMigration(
    uint256[] calldata createdTokenIds,
    uint256[] calldata ownedTokenIds,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    for (uint256 i = 0; i < ownedTokenIds.length; i++) {
      uint256 tokenId = ownedTokenIds[i];
      // Check that the token exists and still owned by the originalAddress
      // so that frontrunning a burn or transfer will not cause the entire tx to revert
      if (_exists(tokenId) && ownerOf(tokenId) == originalAddress) {
        _transfer(originalAddress, newAddress, tokenId);
        emit NFTOwnerMigrated(tokenId, originalAddress, newAddress);
      }
    }

    for (uint256 i = 0; i < createdTokenIds.length; i++) {
      uint256 tokenId = createdTokenIds[i];
      // The creator would be 0 if the token was burned before this call
      if (tokenIdToCreator[tokenId] != address(0)) {
        require(
          tokenIdToCreator[tokenId] == originalAddress,
          "NFT721Creator: Token was not created by the given address"
        );
        _updateTokenCreator(tokenId, newAddress);
        emit NFTCreatorMigrated(tokenId, originalAddress, newAddress);
      }
    }
  }

  /**
   * @notice Allows a split recipient and Foundation to work together in order to update the payment address
   * to a new account.
   * @param signature Message `I authorize Foundation to migrate my account to ${newAccount.address.toLowerCase()}`
   * signed by the original account.
   */
  function adminAccountMigrationForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress,
    bytes calldata signature
  ) public onlyAuthorizedAccountMigration(originalAddress, newAddress, signature) {
    _adminAccountRecoveryForPaymentAddresses(
      paymentAddressTokenIds,
      paymentAddressFactory,
      paymentAddressCallData,
      addressLocationInCallData,
      originalAddress,
      newAddress
    );
  }

  /**
   * @dev Split into a second function to avoid stack too deep errors
   */
  function _adminAccountRecoveryForPaymentAddresses(
    uint256[] calldata paymentAddressTokenIds,
    address paymentAddressFactory,
    bytes memory paymentAddressCallData,
    uint256 addressLocationInCallData,
    address originalAddress,
    address payable newAddress
  ) private {
    // Call the factory and get the originalPaymentAddress
    address payable originalPaymentAddress = _proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // Confirm the original address and swap with the new address
    paymentAddressCallData.replaceAtIf(addressLocationInCallData, originalAddress, newAddress);

    // Call the factory and get the newPaymentAddress
    address payable newPaymentAddress = _proxyCallAndReturnContractAddress(
      paymentAddressFactory,
      paymentAddressCallData
    );

    // For each token, confirm the expected payment address and then update to the new one
    for (uint256 i = 0; i < paymentAddressTokenIds.length; i++) {
      uint256 tokenId = paymentAddressTokenIds[i];
      require(
        tokenIdToCreatorPaymentAddress[tokenId] == originalPaymentAddress,
        "NFT721Creator: Payment address is not the expected value"
      );

      _setTokenCreatorPaymentAddress(tokenId, newPaymentAddress);
      emit PaymentAddressMigrated(tokenId, originalAddress, newAddress, originalPaymentAddress, newPaymentAddress);
    }
  }

  /**
   * @dev Remove the creator record when burned.
   */
  function _burn(uint256 tokenId) internal virtual override {
    delete tokenIdToCreator[tokenId];

    super._burn(tokenId);
  }

  uint256[999] private ______gap;
}

