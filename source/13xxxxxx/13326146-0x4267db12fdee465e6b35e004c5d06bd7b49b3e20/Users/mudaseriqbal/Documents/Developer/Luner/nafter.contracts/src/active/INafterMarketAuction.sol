// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface INafterMarketAuction {
  /**
   * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
   * @param _tokenId uint256 ID of the token
   * @param _amount uint256 wei value that the item is for sale
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setSalePrice(
    uint256 _tokenId,
    uint256 _amount,
    address _owner,
    uint8 _paymentMode
  ) external;

  /**
   * @dev set
   * @param _bidAmount uint256 value in wei to bid.
   * @param _startTime end time of bid
   * @param _endTime end time of bid
   * @param _owner address of the token owner
   * @param _tokenId uint256 ID of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setInitialBidPriceWithRange(
    uint256 _bidAmount,
    uint256 _startTime,
    uint256 _endTime,
    address _owner,
    uint256 _tokenId,
    uint8 _paymentMode
  ) external;

  /**
   * @dev has active bid
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function hasTokenActiveBid(uint256 _tokenId, address _owner) external view returns (bool);
}

