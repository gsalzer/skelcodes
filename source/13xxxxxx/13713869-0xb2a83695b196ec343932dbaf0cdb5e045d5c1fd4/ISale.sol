// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ISale {
  struct Sale {
    uint256 id; // id of sale
    address owner; // address of NFT owner
    address nftContract;
    uint256 tokenId;
    uint256 amount; // amount of NFTs being sold
    uint256 purchased; // amount of NFTs purchased thus far
    uint256 startTime;
    uint256 endTime;
    uint256 price;
    uint256 maxBuyAmount;
    address currency; // use 0xaAaAaAaaAaAaAaaAaAAAAAAAAaaaAaAaAaaAaaAa for ETH
  }

  event NewSale(uint256 indexed id, Sale newSale);
  event SaleCancelled(uint256 indexed saleId);
  event Purchase(
    uint256 saleId, 
    address purchaser, 
    address recipient, 
    uint256 quantity
  );
  event NFTsReclaimed(uint256 indexed id, address indexed owner, uint256 indexed amount);
  event BalanceUpdated(
    address indexed accountOf, 
    address indexed tokenAddress, 
    uint256 indexed newBalance
  );

  function getSaleDetails(uint256 saleId) external view returns(Sale memory);
  function getSaleStatus(uint256 saleId) external view returns(string memory);
  function getClaimableBalance(address account, address token) external view returns(uint256);
  function createSale(
    address nftContract,
    uint256 tokenId,
    uint256 amount,
    uint256 startTime,
    uint256 endTime,
    uint256 price,
    uint256 maxBuyAmount,
    address currency
  ) external returns(uint256);
  function buy(uint256 saleId, address recipient, uint256 amountToBuy, uint256 amountFromBalance) external payable returns(bool);
  function claimNfts(uint256 saleId) external;
  function claimFunds(address tokenContract) external;
  function cancelSale(uint256 saleId) external;
}
