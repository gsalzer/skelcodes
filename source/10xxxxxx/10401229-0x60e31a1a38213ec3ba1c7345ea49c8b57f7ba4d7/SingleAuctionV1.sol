// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Single Auction Header
/// @notice Contain all the events emitted by the Single Auction
contract SingleAuctionHeaderV1 {
    event BidAccepted(uint256 bidValue, address indexed bidder);
    event Payout(uint256 amount, address indexed beneficiary, address indexed contributor);
    event BidCancelled(uint256 bidValue, uint256 ethReturned, address indexed bidder);
    event SaleStarted(address indexed seller, uint256 hammerTime, uint256 hammerBlock);
    event SellingPriceAdjusted(address indexed seller, uint256 amount);
    event Win(address indexed buyer, address indexed seller, uint256 bidValue);
}


/// @author Guillaume Gonnaud 2019
/// @title Single Auction Storage Internal
/// @notice Contain all the storage of the Single Auction declared in a way that does not generate getters for Proxy use
contract SingleAuctionStorageInternalV1 {

    //Used to store the index number of the bidding logic contract
    uint256 internal versionBid;

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

    //A mapping associating each bidder with their associated chainLink
    mapping (address => address) internal bidLinks;

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
    uint256 internal bid_incMax; //10k, or 10%
    uint256 internal bid_incMin; //1k, or 1%
    uint256 internal bid_stepMin; // 10.5k, or 10.5%
    uint256 internal bid_cutOthers; // 500, or 0.5%

    uint256 internal bid_multiplier; //Will be divided by 100 for the calulations. 100 means that doubling the bid leads to 1% extra return

    uint256 internal sale_fee; //Proportion of the bid_Decimals taken as a selling fee. 10% = 10k


    /*
    ==================================================
                        Money section
    ==================================================
    */

    address internal publisher; //The address of the publisher of the cryptograph. Can edit media url and hash.
    address internal charity; //The address to which the chartity cut is being sent to. No special rights.
    address internal thirdParty; //The address of any third party taking a cut. No special rights.
    //The perpetual altruism address. Always take 25%+ for community cryptographs. Same as publisher for official cryptographs.
    address internal perpertualAltruism;

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

    uint256 internal hammerBlockDuration; //The minium number of blocks for which other bidder can come in after a winning offer
    uint256 internal hammerTimeDuration; //The  number of seconds for which other bidder can come in after a winning offer
    uint256 internal hammerBlock; //The block number after which a winning offer can claim a cryptograph
    uint256 internal hammerTime; //The date after which a winning offer can claim a cryptograph

    /*
    ==================================================
                        Binding section
    ==================================================
    */
    address internal auctionHouse; //The address of the auction house
    address internal myCryptograph; //The address of the Cryptograph I'm administrating
    address internal cryFactory; //The address of the cryptograph Factory

    bool internal initialized;
    bool internal isBeingERC2665Approved; //If set to true, a potential new owner has been approved in ERC2665

}


/// @author Guillaume Gonnaud 2019
/// @title Single Auction Storage Public
/// @notice Contain all the storage of the Single Auction declared in a way that generates getters for Logic use
contract SingleAuctionStoragePublicV1 {

    //Used to store the VC index number of the bidding logic conctract
    uint256 internal versionBid;

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

    //A mapping associating each bidder with their associated chainLink
    mapping (address => address) public bidLinks;

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
    uint256 public bid_incMax; //10k, or 10%
    uint256 public bid_incMin; //1k, or 1%
    uint256 public bid_stepMin; // 10.5k, or 10.5%
    uint256 public bid_cutOthers; // 500, or 0.5%

    uint256 public bid_multiplier; //Will be divided by 100 for the calulations. 100 mean that doubling the bid mean 1% extra return

    uint256 public sale_fee; //Proportion of the bid_Decimals taken as a selling fee. 10% = 10k

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

    uint256 public hammerBlockDuration; //The minium number of blocks for which other bidder can come in after a winning offer
    uint256 public hammerTimeDuration; //The  number of seconds for which other bidder can come in after a winning offer
    uint256 public hammerBlock; //The block number after which a winning offer can claim a cryptograph
    uint256 public hammerTime; //The date after which a winning offer can claim a cryptograph

    /*
    ==================================================
                        Binding section
    ==================================================
    */
    address public auctionHouse; //The address of the auction house
    address public myCryptograph; //The address of the Cryptograph I'm administrating
    address public cryFactory; //The address of the cryptograph Factory

    bool public initialized;
    bool public isBeingERC2665Approved; //If set to true, a potential new owner has been approved in ERC2665
}


