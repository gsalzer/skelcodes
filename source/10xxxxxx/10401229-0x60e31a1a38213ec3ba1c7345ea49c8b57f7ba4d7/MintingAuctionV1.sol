// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Minting Auction Header
/// @notice Contain all the events emitted by the Minting Auction
contract MintingAuctionHeaderV1 {
    event BidAccepted(uint256 bidValue, address bidder);
    event Payout(uint256 amount, address beneficiary, address contributor);
    event BidCancelled(uint256 bidValue, uint256 ethReturned, address bidder);
    event SaleStarted(address seller, uint256 hammerTime, uint256 hammerBlock);
    event SellingPriceAdjusted(address seller, uint256 amount);
    event Win(address buyer, address seller, uint256 bidValue);
}


/// @author Guillaume Gonnaud 2019
/// @title Minting Auction Storage Internal
/// @notice Contain all the storage of the Minting Auction declared in a way that don't generate getters for Proxy use
contract MintingAuctionStorageInternalV1 {

     /*
    ==================================================
                        Bidding section
    ==================================================
    */

    //The current bids made by each address
    mapping (address => uint) internal currentBids;

    //The current amount of wei each address receive when outbid as the highest bid.
    mapping (address => uint) internal duePayout; //How much the bidder make

    //The current highest bidder;
    address internal highestBidder;

    //The current amount of unsettled payouts distributed for the current bidding process
    uint256 internal unsettledPayouts;

    //The default starting price
    uint256 internal startingPrice;

    //The current selling price
    uint256 internal sellingPrice;

    /*
    ==================================================
                        Calculations section
    ==================================================
    */

    /*
    For a standing bid s and a new bid n, we express the return on the new bid as:

    incentive(n,s) % = min[ incmax , incmin + m * (n- s * (1+ stepmin)) / (s * (1+ stepmin))]

    Where:
    stepmin is the minimum bid increment, expressed as a fraction of the current standing bid (ex : 0.01 for 1/10 or 10%)
    incmin is the minimum incentive, expressed as a fraction
    incmax is the maximum incentive, expressed as a fraction
    m is the multiplier effect, expressed as a positive real number

    */

    //Values used to calculate the payouts.
    uint256 internal bid_Decimals; //100k, or 100%
    uint256 internal bid_incMax; //4.5k, or 4.5%
    uint256 internal bid_incMin; //1k, or 1%
    uint256 internal bid_stepMin; //5k, or 5%
    uint256 internal bid_cutOthers; // 500, or 0.5%

    uint256 internal bid_multiplier; //Will be divided by 100 for the calulations. 100 mean that doubling the bid mean 1% extra return

    /*
    ==================================================
                        Money section
    ==================================================
    */

    address internal publisher; //The address of the publisher of the cryptograph. Can edit media url and hash.
    address internal charity; //The address to which the chartity cut is being sent to
    address internal thirdParty; //The address of any third party taking a cut
    address internal perpertualAltruism; //The perpetual altruism address

    //The granularity of the redistribution is 0.001%. 100 000 = all the money
    uint256 internal publisherCut;
    uint256 internal charityCut;
    uint256 internal thirdPartyCut;
    uint256 internal perpetualAltruismCut;

    /*
    ==================================================
                        Timing section
    ==================================================
    */
    uint256 internal startTime; //The start date of the initial auction
    uint256 internal endTime; //The end date of the initial auction

    /*
    ==================================================
                        Binding section
    ==================================================
    */
    address internal auctionHouse; //The address of the auction house
    address internal myCryptograph; //The address of the Cryptograph I'm administrating
    address internal cryFactory; //The address of the cryptograph Factory

    bool internal initialized;

    //A mapping associating each bidder with their associated chainLink
    mapping (address => address) internal bidLinks;

    address internal initiator; //We keep the address of our initator for future minting

    uint256 internal numberOfBids; //Current number of standing bids
    uint256 internal maxSupply; //Maximum number of bid to keep
    address internal tailBidder; //The address of the current bottom bidder
}


/// @author Guillaume Gonnaud 2019
/// @title Minting Auction Storage Public
/// @notice Contain all the storage of the Minting Auction declared in a way that generate getters for Logic use
contract MintingAuctionStoragePublicV1 {
      /*
    ==================================================
                        Bidding section
    ==================================================
    */

    //The current bids made by each address
    mapping (address => uint) public currentBids;

    //The current amount of wei each address receive when outbid as the highest bid.
    mapping (address => uint) public duePayout; //How much the bidder make

    //The current highest bidder;
    address public highestBidder;

    //The current amount of unsettled payouts distributed for the current bidding process
    uint256 public unsettledPayouts;

    //The default starting price
    uint256 public startingPrice;

    //The current selling price
    uint256 public sellingPrice;

    /*
    ==================================================
                        Calculations section
    ==================================================
    */

    /*
    For a standing bid s and a new bid n, we express the return on the new bid as:

    incentive(n,s) % = min[ incmax , incmin + m * (n- s * (1+ stepmin)) / (s * (1+ stepmin))]

    Where:
    stepmin is the minimum bid increment, expressed as a fraction of the current standing bid (ex : 0.01 for 1/10 or 10%)
    incmin is the minimum incentive, expressed as a fraction
    incmax is the maximum incentive, expressed as a fraction
    m is the multiplier effect, expressed as a positive real number

    */

    //Values used to calculate the payouts.
    uint256 public bid_Decimals; //100k, or 100%
    uint256 public bid_incMax; //4.5k, or 4.5%
    uint256 public bid_incMin; //1k, or 1%
    uint256 public bid_stepMin; //5k, or 5%
    uint256 public bid_cutOthers; // 500, or 0.5%

    uint256 public bid_multiplier; //Will be divided by 100 for the calulations. 100 mean that doubling the bid mean 1% extra return

    /*
    ==================================================
                        Money section
    ==================================================
    */

    address public publisher; //The address of the publisher of the cryptograph. Can edit media url and hash.
    address public charity; //The address to which the chartity cut is being sent to
    address public thirdParty; //The address of any third party taking a cut
    address public perpertualAltruism; //The perpetual altruism address

    //The granularity of the redistribution is 0.001%. 100 000 = all the money
    uint256 public publisherCut;
    uint256 public charityCut;
    uint256 public thirdPartyCut;
    uint256 public perpetualAltruismCut;

    /*
    ==================================================
                        Timing section
    ==================================================
    */
    uint256 public startTime; //The start date of the initial auction
    uint256 public endTime; //The end date of the initial auction

    /*
    ==================================================
                        Binding section
    ==================================================
    */
    address public auctionHouse; //The address of the auction house
    address public myCryptograph; //The address of the Cryptograph I'm administrating
    address public cryFactory; //The address of the cryptograph Factory

    bool public initialized;

    //A mapping associating each bidder with their associated chainLink
    mapping (address => address) public bidLinks;

    address public initiator; //We keep the address of our initator for future minting

    uint256 public numberOfBids; //Current number of standing bids
    uint256 public maxSupply; //Maximum number of bids to keep
    address public tailBidder; //The address of the current bottom bidder

}


