// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./MintingAuctionV1.sol";
import "./CryptographFactoryV1.sol";
import "./AuctionHouseLogicV1.sol";
import "./TheCryptographLogicV1.sol";
import "./CryptographInitiator.sol";
import "./BidLink.sol";

/*
    This contract idea is rather complex.
    => Implement a Generalized GBM Auction (GGBMA) for initial supply of a series of limited editions within the same auction (instead of each token being sold independantly)

    >During the initial sale, everyone can place a bid at any amount of money (one exception, see below)
    >You can't retract your bid
    >You can only have one active bid, and can only re-bid higher than YOUR previous bid
    >If you want to place a bid higher than the current highest bid, it need to be at least 5% higher
    >When the top bid is being displaced by a new bid, the previous top bid owner receive GBM incentives. All others bidders don't
    >No new bid can be placed after the initial period
    >At the end of the auction, you can mint a cryptograph where the serial # match your position in the auction
        -> Highest bidder get #1, second highest get #2, etc...
    >If there was a limited supply, any bidder that was ranked below the supply amount can cancel their bid and recover the eth

*/

/// @author Guillaume Gonnaud 2019
/// @title Minting Auction Logic Code
/// @notice Based on the Single Auction smart contracts but with overrides
contract MintingAuctionLogicV1 is VCProxyData, MintingAuctionHeaderV1, MintingAuctionStoragePublicV1 {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall hence its memory state is irrelevant
    constructor() public
    {
        //Self intialize (nothing)
    }

    //Modifier for functions that requires to be called only by the Auction house
    modifier restrictedToAuctionHouse(){
        require((msg.sender == auctionHouse), "Only the auction house smart contract can call this function");
        _;
    }

    /// @notice Init function of the MintingAuction
    /// @param _myCryptograph The address of the cryptograph this auction is paired with
    /// @param _cryInitiator The address of the initator containing the details of our auction
    /// @param _initialize true => can't change any spec afterward. false => can initialize again.
    function initAuction(
            address _myCryptograph,
            address _cryInitiator,
            bool _initialize
        ) public {

        require(!initialized, "This auction is already initialized");
        initialized = _initialize; //Are we locking ?

        //we must be either perpetual altruism OR never inited before
        require(auctionHouse == address(0) || msg.sender == cryFactory,"Only Perpetual altruism can change a yet to be locked auction");
        cryFactory = msg.sender;

        /*
        ==================================================
                            Bidding section
        ==================================================
        */

        startingPrice = CryptographInitiator(_cryInitiator).startingPrice(); //The first bid that needs to be outbid is 1 Wei
        sellingPrice = 0; //A newly minted Cryptograph does not have an owner willing to sell

        /*
        ==================================================
                        Calculations section
        ==================================================
        */
        bid_Decimals = 100000;  //100k, or 100%
        bid_incMax = 10000; //10k, or 10%
        bid_incMin = 1000; //1k, or 1%
        bid_stepMin = 10500; //10.5k, or 10.5%
        bid_cutOthers = 500; // 500, or 0.5%
        bid_multiplier = 9000; //9000 = Doubling bid yield max gain (1%+9% = 10%)

        /*
        ==================================================
                            Money section
        ==================================================
        */
        //Setting up money flow
        perpertualAltruism = CryptographFactoryStoragePublicV1(cryFactory).officialPublisher();
        perpetualAltruismCut = CryptographInitiator(_cryInitiator).perpetualAltruismCut();
        publisher = CryptographInitiator(_cryInitiator).publisher();
        publisherCut = CryptographInitiator(_cryInitiator).publisherCut();
        charity = CryptographInitiator(_cryInitiator).charity();
        charityCut = CryptographInitiator(_cryInitiator).charityCut();
        thirdParty = CryptographInitiator(_cryInitiator).thirdParty();
        thirdPartyCut = CryptographInitiator(_cryInitiator).thirdPartyCut();
        maxSupply = CryptographInitiator(_cryInitiator).maxSupply();

        //Setting up timings

        startTime = CryptographInitiator(_cryInitiator).auctionStartTime();
        endTime = CryptographInitiator(_cryInitiator).auctionStartTime() + CryptographInitiator(_cryInitiator).auctionSecondsDuration();

        auctionHouse = CryptographFactoryStoragePublicV1(cryFactory).targetAuctionHouse();
        myCryptograph = _myCryptograph;
        initiator = _cryInitiator;
    }

    /// @notice Make an official auction unmodifiable once we are certain the parameters are correct
    /// @dev Only callable by perpetual altruism
    function lock() external{
        require(msg.sender == cryFactory, "Only Perpetual altruism can lock the initialization");
        initialized = true;
    }

    /// @notice Place a bid to own a cryptograph and distribute the incentives
    /// @dev Only callable by the Auction House
    /// @param _newBidAmount The amount of the new bid
    /// @param _newBidder The address of the bidder
    function bid(uint256 _newBidAmount, address _newBidder) external payable restrictedToAuctionHouse(){

        /*
        ========================== money check ==========================
        */

        //Unitiliazed cryptographs can't be bid upon
        require(initialized, "This auction has not been properly set up yet");
        //Did we send the proper amount of money, are we allowed to bid ?
        require(_newBidAmount == msg.value + currentBids[_newBidder], "Amount of money sent incorrect"); //Also protects from self-underbiding
        //check to be made : is the new bid big enough ?
        require(numberOfBids != maxSupply || currentBids[tailBidder] < _newBidAmount, "Your bid is lower than the lowest bid");

        require( //Either fresh bid OR meeting the standing bid * the step OR below highest bidder
                    ( (highestBidder == address(0)) && startingPrice <= _newBidAmount ) ||
                    ( (highestBidder != address(0)) && (currentBids[highestBidder] * (bid_Decimals + bid_stepMin) <= (_newBidAmount * bid_Decimals) )) ||
                    (  (highestBidder != address(0)) && (currentBids[highestBidder] >= _newBidAmount) ),
                "New bid amount does not meet an authorized amount");

        /*
        ========================== Timing check ==========================
        */

        //We must be past the initial auction start
        require(now >= startTime, "You can only bid once the initial auction has started");
        require(now < endTime, "GGMBA do not allow bidding past the ending time");

        //Emit the bid acceptance event before triggering the payouts
        emit BidAccepted(_newBidAmount, _newBidder);

        /*
        ========================== Payouts ==========================
        */

        uint256 duePay;
        //if we are not an underbidder...
        if((currentBids[highestBidder] < _newBidAmount)){
            //In a GGBMA, every new highest bidder pays a 0.5% fee
            duePay = (_newBidAmount * bid_cutOthers)/bid_Decimals;
            unsettledPayouts += duePay;
            distributeStakeholdersPayouts(duePay, _newBidder);
            //Send the payout to the previous highest bidder
            if(highestBidder != address(0)){
                duePay = duePayout[highestBidder];
                if(duePay != 0){
                    unsettledPayouts += duePay;
                    emit Payout(duePay,  highestBidder,  _newBidder);
                    AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: duePay }(highestBidder, _newBidder);
                }
            }

            /*
            ========================== Reward ==========================
            */

            //Set the new payout amount we will receive when outbid (Only for new highest bidders)
            calculateReward(_newBidAmount, _newBidder);
        }

        /*
        ===================== Bid Cancellation And Registering =====================
        */
        uint256 toSend;

        //We need to cancel our own previous lower bid OR to update the number of bids
        if(currentBids[_newBidder] != 0){

            BidLink(bidLinks[_newBidder]).setBidAmount(_newBidAmount); //Updating our bid amount

            //Updating our neigbors link
            if( BidLink(bidLinks[_newBidder]).above() != address(0x0)){
                BidLink(BidLink(bidLinks[_newBidder]).above()).setBelow(BidLink(bidLinks[_newBidder]).below()); //Unlinking above us
            }

            if( BidLink(bidLinks[_newBidder]).below() != address(0x0)){
                BidLink(BidLink(bidLinks[_newBidder]).below()).setAbove(BidLink(bidLinks[_newBidder]).above()); //Unlinking below us
            }
            emit BidCancelled(currentBids[_newBidder], currentBids[_newBidder], _newBidder); //Emitting the event

        } else {
            //Create a bid link
            bidLinks[_newBidder] = address(new BidLink(_newBidder, _newBidAmount));

            //Refunding/Setting the tail.
            if(numberOfBids == maxSupply && maxSupply != 0){
                //Max number of bids reached, refunding the tail bid
                toSend = currentBids[tailBidder];
                currentBids[tailBidder] = 0;
                if(toSend != 0){
                    //Send back all the money : no payout settlement required
                    emit BidCancelled(toSend, toSend, tailBidder);
                    AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(tailBidder, tailBidder);
                }
                //Updating the tail bid
                BidLink(BidLink(bidLinks[tailBidder]).above()).setBelow(address(0x0)); //Unlinking
                tailBidder = BidLink(BidLink(bidLinks[tailBidder]).above()).bidder(); //Updating the tail


            } else {
                //Max not reached
                numberOfBids++;
            }
        }



        currentBids[_newBidder] = _newBidAmount; //Set the amount of the bid

        //Browse the BidLink chain until the link above us have a bid greater or equal to us
        address currentLink = bidLinks[highestBidder];

        if(currentLink == address(0x0)){
            tailBidder = _newBidder; //We are the only bidder = we are also the lowest bidder
        } else {
            //Browsing down the linked list
            while( BidLink(currentLink).below() != address(0x0) && BidLink(BidLink(currentLink).below()).bidAmount() >= _newBidAmount){
                    currentLink = BidLink(currentLink).below(); //Browse the chain
            }
        }

        //Are we the new highest bidder ?
        if(currentBids[highestBidder] < _newBidAmount){
            highestBidder = _newBidder; //We are the highest bidder
            BidLink(bidLinks[_newBidder]).setBelow(currentLink); //Setting ourselves as above the old head
            if(currentLink != address(0x0)){    //Only if there is a previous head
                BidLink(currentLink).setAbove(bidLinks[_newBidder]); //Setting the old head as below us
            }
        } else { //Normally inserting ourself in the chain
            BidLink(bidLinks[_newBidder]).setAbove(currentLink); //Above us is the current link
            BidLink(bidLinks[_newBidder]).setBelow(BidLink(currentLink).below()); //Below us is the previous tail of the current link
            if(BidLink(bidLinks[_newBidder]).below() != address(0x0)){  //If we have a new tail
                BidLink(BidLink(bidLinks[_newBidder]).below()).setAbove(bidLinks[_newBidder]); //We are above our new tail
            } else {
                //We are the new tail
                tailBidder = _newBidder;
            }
            //We should always have a new head (as we are not highest bidder)
            BidLink(BidLink(bidLinks[_newBidder]).above()).setBelow(bidLinks[_newBidder]); //Our new head has us as a tail
        }

        //The chainlink is now ordered properly

    }

    /// @notice USed to check which can of auction we are
    /// @dev Only callable by the Auction House.
    /// @param _newOwner The address of the bidder wishing to mint a new cryptograph
    /// @return 0 if a normal auction, 1 if a minting auction
    function win(address _newOwner) external restrictedToAuctionHouse() view returns(uint){
        require(currentBids[_newOwner] != 0, "You don't have any active bid on this auction");
        require(now > endTime, "The initial auction is not over yet");

        return 1;
    }

    /// @notice Distribute the bid of an auction winner
    /// @dev Only callable by the Auction House.
    /// @param _newOwner The address of the bidder wishing to mint a new cryptograph
    function distributeBid(address _newOwner) external restrictedToAuctionHouse(){

         if(_newOwner == highestBidder){
            distributeStakeholdersPayouts(currentBids[highestBidder] - unsettledPayouts, _newOwner); //Payouts are deduced from the highest bid
        } else {
            distributeStakeholdersPayouts(currentBids[_newOwner], _newOwner);
        }

        currentBids[_newOwner] = 0;
    }

    /// @notice Function used to distribute an arbitrary amount of money among non-bidders
    /// @dev Only callable internally
    /// @param _amount The amount of money to spread
    /// @param _contributor The address of the gracious donor
    function distributeStakeholdersPayouts(uint256 _amount, address _contributor) internal{
        uint256 toDistribute = _amount;
        uint256 toSend;

        //Pay the charity
        toSend = (charityCut * _amount) / bid_Decimals;
        toDistribute -= toSend;
        if(toSend != 0){
            emit Payout(toSend,  charity,  _contributor);
            AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(charity, _contributor);
        }

        //Pay the publisher
        toSend = (publisherCut * _amount) / bid_Decimals;
        toDistribute -= toSend;
        if(toSend != 0){
            emit Payout(toSend,  publisher,  _contributor);
            AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(publisher, _contributor);
        }

        //Pay the thirdParty
        toSend = (thirdPartyCut * _amount) / bid_Decimals;
        toDistribute -= toSend;
        if(toSend != 0){
            emit Payout(toSend,  thirdParty,  _contributor);
            AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(thirdParty, _contributor);
        }

        //Pay perpetual Altruism the reminder (25%). only non-null guaranteed address, so send any rounding errors there
        toSend = toDistribute;
        if(toSend != 0){
            emit Payout(toSend,  perpertualAltruism,  _contributor);
            AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(perpertualAltruism, _contributor);
        }
    }

    /// @notice Calculating and setting how much payout a bidder will receive if outbid
    /// @dev Only callable internally
    /// @param _newBid The amount of money in the new bid
    /// @param _bidder The address of the new bidder
    function calculateReward(uint256 _newBid, address _bidder) internal{

        //Calculating how much payout we will receive if we are outbid

        //Init the baseline bid we need to perform against
        uint256 baseBid = currentBids[highestBidder] * (bid_Decimals + bid_stepMin) / bid_Decimals;
        if(baseBid == 0){
            baseBid = startingPrice;

            //Do not divide by 0
            if(baseBid == 0){
                baseBid = 1;
            }
        }

        //We calculate our baseline reward. We square the decimals to guarantee a granularity of at least 1/bid_Decimals instead of 1/bid_multiplier
        //This also somewhat limits the hardcap for a reward to max_UInt256/10^11 => Not a problem as this amount of eth will not be minted
        uint256 decimaledRatio = ((bid_Decimals * bid_multiplier * (_newBid - baseBid) ) / baseBid) + bid_incMin * bid_Decimals;

        //If we go over the maximum payout, we set the reward to the maximum payout
        if(decimaledRatio > (bid_Decimals * bid_incMax)){
            decimaledRatio = bid_Decimals * bid_incMax;
        }

        duePayout[_bidder] = (_newBid * decimaledRatio)/(bid_Decimals*bid_Decimals);
    }
}

