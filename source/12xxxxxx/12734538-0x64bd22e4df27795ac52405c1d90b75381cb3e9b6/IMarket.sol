// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarket {

   enum CURRENCY{ ETH, TOKEN}

    struct Auction {
        bool active;
        address seller;
        address owner;
        uint256 value;
        uint256 endTime;
        CURRENCY currency;
    }



    function listOnAuction(uint256 _tokenId, uint256 _price, CURRENCY currency, uint256 _days) external returns (Auction memory);

    function bid(uint256 _tokenId,uint256 _price) external payable returns (Auction memory);

    function claimNft(uint256 _tokenId) external returns (uint256);

    function withdraw(address _address, uint256 _value, CURRENCY currency) external ;

    function getAuction(uint256 _tokenId) external view returns (Auction memory);

    
   function setTokenAddress(address erc721contract, address erc20contract) external ;

   // function setERC721TokenAddress(address _address) external ;

//    function setERC20TokenAddress(address _address) external ;

    function setFee(uint256 fee, uint256 tokenFee) external;

    function setNextBidPercentage(uint256 nextBidPercent) external;



    event ListOnAuction(address indexed owner, uint256  tokenId,uint256 price, uint256 endTime, CURRENCY currency);

    event Bid(address  bidder, uint256 indexed tokenId, uint256 value, CURRENCY currency);

    event ClaimNft(address collector, uint256 indexed tokenId, uint256 value);
}

