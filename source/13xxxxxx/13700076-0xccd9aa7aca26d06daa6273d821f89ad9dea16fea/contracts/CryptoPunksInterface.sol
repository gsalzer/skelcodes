// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.10;

abstract contract CryptoPunksInterface {
  uint256 public totalSupply;

  struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    uint256 minValue; // in ether
    address onlySellTo; // specify to sell only to a specific person
  }

  // A record of punks that are offered for sale at a specific minimum value, and perhaps to a specific person
  mapping(uint256 => Offer) public punksOfferedForSale;

  mapping(uint256 => address) public punkIndexToAddress;

  function offerPunkForSaleToAddress(
    uint256 punkIndex,
    uint256 minSalePriceInWei,
    address toAddress
  ) external virtual;

  function buyPunk(uint256 punkIndex) external payable virtual;
}

