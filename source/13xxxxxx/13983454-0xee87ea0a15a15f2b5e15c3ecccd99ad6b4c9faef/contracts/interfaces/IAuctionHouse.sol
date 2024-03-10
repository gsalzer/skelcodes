// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.6;

interface IAuctionHouse {
    struct Auction {
        // ID for the NFT (ERC721 token ID)
        uint256 nftId;
        // The current highest bid amount
        uint256 amount;
        // The time that the auction started
        uint256 startTime;
        // The time that the auction is scheduled to end
        uint256 endTime;
        // The address of the current highest bid
        address payable bidder;
        // Whether or not the auction has been settled
        bool settled;
    }

    event AuctionCreated(
        uint256 indexed nftId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed nftId,
        address sender,
        uint256 value
    );

    event AuctionSettled(
        uint256 indexed nftId,
        address winner,
        uint256 amount
    );

    event AuctionAmountUpdated(uint256 amount);

    event AuctionReservePriceUpdated(uint256 reservePrice);

    event AuctionDurationUpdated(uint256 duration);

    event AuctionMinBidIncrementPercentageUpdated(
        uint256 minBidIncrementPercentage
    );

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function createBid(uint256 nftId) external payable;

    function pause() external;

    function unpause() external;

    function setAmount(uint256 amount) external;

    function setReservePrice(uint256 reservePrice) external;

    function setDuration(uint256 duration) external;

    function setMinBidIncrementPercentage(uint8 minBidIncrementPercentage)
    external;
}

