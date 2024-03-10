// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

import "../interfaces/IFNDNFT721.sol";
import "../interfaces/ITokenCreatorPaymentAddress.sol";
import "../interfaces/ITokenCreator.sol";
import "../interfaces/IGetRoyalties.sol";
import "../interfaces/IHasSecondarySaleFees.sol";
import "../interfaces/IOwnable.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./OZ/ERC165Checker.sol";

import "./Constants.sol";

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
  Constants,
  ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
  using ERC165Checker for address;

  /**
   * @dev Returns the destination address for any payments to the creator,
   * or address(0) if the destination is unknown.
   * It also checks if the current seller is the creator for isPrimary checks.
   */
  // solhint-disable-next-line code-complexity
  function _getCreatorPaymentInfo(
    address nftContract,
    uint256 tokenId,
    address seller
  )
    internal
    view
    returns (
      address payable[] memory recipients,
      uint256[] memory splitPerRecipientInBasisPoints,
      bool isCreator
    )
  {
    // All NFTs implement 165 so we skip that check, individual interfaces should return false if 165 is not implemented

    // 1st priority: getTokenCreatorPaymentAddress w/ 165
    if (nftContract.supportsERC165Interface(type(ITokenCreatorPaymentAddress).interfaceId)) {
      try
        ITokenCreatorPaymentAddress(nftContract).getTokenCreatorPaymentAddress{ gas: READ_ONLY_GAS_LIMIT }(tokenId)
      returns (address payable tokenCreatorPaymentAddress) {
        if (tokenCreatorPaymentAddress != address(0)) {
          recipients = new address payable[](1);
          recipients[0] = tokenCreatorPaymentAddress;
          if (tokenCreatorPaymentAddress == seller) {
            // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
            return (recipients, splitPerRecipientInBasisPoints, true);
          }
          // else persist recipients but look for other isCreator definitions
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 2nd priority: tokenCreator w/ 165
    if (nftContract.supportsERC165Interface(type(ITokenCreator).interfaceId)) {
      try IFNDNFT721(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (address payable _creator) {
        if (_creator != address(0)) {
          if (recipients.length == 0) {
            // Only pay the tokenCreator if there wasn't a tokenCreatorPaymentAddress defined
            recipients = new address payable[](1);
            recipients[0] = _creator;
          }
          // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
          return (recipients, splitPerRecipientInBasisPoints, _creator == seller);
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 3rd priority: getRoyalties
    if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IGetRoyalties).interfaceId)) {
      try IGetRoyalties(nftContract).getRoyalties{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients,
        uint256[] memory recipientBasisPoints
      ) {
        if (_recipients.length > 0 && _recipients.length == recipientBasisPoints.length) {
          bool hasRecipient = false;
          for (uint256 i = 0; i < _recipients.length; i++) {
            if (_recipients[i] != address(0)) {
              hasRecipient = true;
              if (_recipients[i] == seller) {
                isCreator = true;
              }
            }
          }
          if (hasRecipient) {
            return (_recipients, recipientBasisPoints, isCreator);
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 4th priority: getFee*
    if (recipients.length == 0 && nftContract.supportsERC165Interface(type(IHasSecondarySaleFees).interfaceId)) {
      try IHasSecondarySaleFees(nftContract).getFeeRecipients{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
        address payable[] memory _recipients
      ) {
        if (_recipients.length > 0) {
          try IHasSecondarySaleFees(nftContract).getFeeBps{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (
            uint256[] memory recipientBasisPoints
          ) {
            if (_recipients.length == recipientBasisPoints.length) {
              bool hasRecipient = false;
              for (uint256 i = 0; i < _recipients.length; i++) {
                if (_recipients[i] != address(0)) {
                  hasRecipient = true;
                  if (_recipients[i] == seller) {
                    isCreator = true;
                  }
                }
              }
              if (hasRecipient) {
                return (_recipients, recipientBasisPoints, isCreator);
              }
            }
          } catch // solhint-disable-next-line no-empty-blocks
          {
            // Fall through
          }
        }
      } catch // solhint-disable-next-line no-empty-blocks
      {
        // Fall through
      }
    }

    // 5th priority: owner
    try IOwnable(nftContract).owner{ gas: READ_ONLY_GAS_LIMIT }() returns (address owner) {
      if (owner != address(0)) {
        if (recipients.length == 0) {
          // Only pay the owner if there wasn't a tokenCreatorPaymentAddress defined
          recipients = new address payable[](1);
          recipients[0] = payable(owner);
        }
        // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
        return (recipients, splitPerRecipientInBasisPoints, owner == seller);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // 6th priority: tokenCreator w/o requiring 165
    try IFNDNFT721(nftContract).tokenCreator{ gas: READ_ONLY_GAS_LIMIT }(tokenId) returns (address payable _creator) {
      if (_creator != address(0)) {
        if (recipients.length == 0) {
          // Only pay the tokenCreator if there wasn't a tokenCreatorPaymentAddress defined
          recipients = new address payable[](1);
          recipients[0] = _creator;
        }
        // splitPerRecipientInBasisPoints is not relevant when only 1 recipient is defined
        return (recipients, splitPerRecipientInBasisPoints, _creator == seller);
      }
    } catch // solhint-disable-next-line no-empty-blocks
    {
      // Fall through
    }

    // If no valid payment address or creator is found, return 0 recipients
  }

  // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
  uint256[500] private ______gap;
}

