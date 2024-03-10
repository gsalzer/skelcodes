// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./SingleAuctionV1.sol";
import "./CryptographFactoryV1.sol";
import "./AuctionHouseLogicV1.sol";
import "./TheCryptographLogicV1.sol";
import "./CryptographInitiator.sol";
import "./BidLinkSimple.sol";


/// @author Guillaume Gonnaud 2019
/// @title Single Auction Logic Code
/// @notice Implements a GBM auction. See white paper for the details. Logic code, to be casted on a proxy.
contract SingleAuctionLogicV1 is VCProxyData, SingleAuctionHeaderV1, SingleAuctionStoragePublicV1  {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall and hence its memory state is irrelevant
    constructor () public
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

        startingPrice = CryptographInitiator(_cryInitiator).startingPrice(); //The first bid that need to be outbid is 1 Wei
        sellingPrice = 0; //A newly minted cryptograph doesn't have an owner willing to sell

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
        bid_multiplier = 11120; // 9000 = Doubling step min bid yield max gain (1%+9% = 10%). 

        sale_fee = 10000; //10k, or 10%

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

        //Setting up timings
        startTime = CryptographInitiator(_cryInitiator).auctionStartTime();
        endTime = CryptographInitiator(_cryInitiator).auctionStartTime() + CryptographInitiator(_cryInitiator).auctionSecondsDuration();

        hammerBlockDuration = 10; //Minimum 10 blocks
        hammerTimeDuration = 36*60*60; //The new perpetual auction will last for 36 hours at least
        delete hammerBlock;
        delete hammerTime;

        auctionHouse = CryptographFactoryStoragePublicV1(cryFactory).targetAuctionHouse();
        myCryptograph = _myCryptograph;
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
        //Empty, as we are supposed to execute SingleAuctionBidLogic bid function but better have this function in the ABI
    }

    /// @notice Cancel a bid placed previously by a bidder
    /// @dev Only callable by the Auction House
    /// @param _bidder The address of the bidder wanting to cancel his bid
    function cancelBid(address _bidder) external restrictedToAuctionHouse(){

        //We can only cancel existing bids
        require(currentBids[_bidder] != 0, "Can't cancel a bid that does not exist");

        //We can only cancel past the initial auction
        require(TheCryptographLogicV1(myCryptograph).owner() != address(0), "Bids cannot be manually cancelled during the initial auction");

        //We can't cancel during hammerTime if we are the highest bidder
        require(hammerTime == 0 || _bidder != highestBidder, "The highest bid cannot be cancelled once a seller accepted a sale");

        uint256 toSend = currentBids[_bidder];

        //If we are the highest bidder we have to settle the payouts before cancelling
        //unsettledPayouts = 0 for the highest bidder if either first bidder or someone cancelled above
        if(_bidder == highestBidder ){
            //Deduce from amount of money we get back the unsettled payout
            toSend -= unsettledPayouts;
            unsettledPayouts = 0;

            //Finding the new highest bidder :
            //Explore the below link of the highest bidder. (We are cancelling a bid, so a highest bidder exist)
            address _linkHighest = BidLinkSimple(bidLinks[_bidder]).below();
            //If the below link exist, then the associated bidder is the next highest bidder
            if(_linkHighest != address(0x0)){
                highestBidder = BidLinkSimple(_linkHighest).bidder();
            } else {
                //No more bidders : we are cancelling ourselves
                delete highestBidder;
            }
        }

        //Emit the cancellation event
        emit BidCancelled(currentBids[_bidder], toSend, _bidder);

        //Reset our bid related variables
        currentBids[_bidder] = 0;
        duePayout[_bidder] = 0;


        //Updating our neigbors link
        if( BidLinkSimple(bidLinks[_bidder]).above() != address(0x0)){
            BidLinkSimple(BidLinkSimple(bidLinks[_bidder]).above()).setBelow(BidLinkSimple(bidLinks[_bidder]).below()); //Unlinking above us
        }

        if( BidLinkSimple(bidLinks[_bidder]).below() != address(0x0)){
            BidLinkSimple(BidLinkSimple(bidLinks[_bidder]).below()).setAbove(BidLinkSimple(bidLinks[_bidder]).above()); //Unlinking below us
        }

        //Finally, we send the funds back to the auction house
        AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(_bidder, _bidder);

    }

    /// @notice Set an instant sale price. If set to 0, instant sale can't be triggered.
    /// @dev Only callable by the Auction House. Can't be cancelled
    /// @param _seller The address of the owner wishing to sell the Cryptograph
    /// @param _sellPrice The minimum amount of eth the seller wants to get
    function setSellingPrice(address _seller, uint256 _sellPrice) external restrictedToAuctionHouse(){

        require(!isBeingERC2665Approved, "You can't auction a cryptograph that a third party can reclaim");

        require(_seller == TheCryptographLogicV1(myCryptograph).owner(), "The seller can only be the owner");
        require(hammerTime == 0, "A sale is already in progress");

        sellingPrice = _sellPrice;

        emit SellingPriceAdjusted(_seller, _sellPrice);

        if(currentBids[highestBidder] >= _sellPrice && _sellPrice != 0){ //Start a sale if the selling price is already met by the highest bidder
            hammerTime = now + hammerTimeDuration;
            hammerBlock = block.number + hammerBlockDuration;
            emit SaleStarted(_seller, hammerTime, hammerBlock);
        }

        //Resetting Renatus timer
        TheCryptographLogicV1(myCryptograph).renatus();

    }

    /// @notice Assign the cryptograph to its new legitmate owner. Only callable after the initial Auction or HammerTime
    /// @dev Only callable by the Auction House.
    /// @param _newOwner The address of the bidder wishing to win the cryptograph
    /// @return 0 if a normal auction, 1 if a minting auction
    function win(address _newOwner) external restrictedToAuctionHouse() returns(uint){

        //Only the highest bidder can win a cryptograph
        require(_newOwner == highestBidder, "Only the highest bidder can win the Cryptograph");
     
        //startingPrice being reset to 1 wei
        if(startingPrice != 1){
            startingPrice = 1;
        }

        //Fire the transfer following a win event
        emit Win(_newOwner, TheCryptographLogicV1(myCryptograph).owner(), currentBids[highestBidder]);

        uint256 toSend;

        //If there is no owner yet
        if(TheCryptographLogicV1(myCryptograph).owner() == address(0)){
            //We are in the initial sale process
            require(now > endTime, "The initial auction is not over yet");

            //All the proceeds of the sale are distributed to third parties
            distributeStakeholdersPayouts(currentBids[highestBidder] - unsettledPayouts, _newOwner);

        } else {
            //We are in the perpetual sale process

            //A sale must be happening and other bidders must have had an opportunity to place their own bids
            require(hammerTime != 0, "No sales are happening right now");
            require(now > hammerTime, "Not enough time has elapsed since the seller accepted the sale");
            require(block.number > hammerBlock, "Not enough blocks have been mined since the seller accepted the sale");

            delete hammerBlock; //Reset the minimal sale block
            delete hammerTime; //Reset the minmimal sale time

            //10% of the seller proceed is distributed to third parties
            toSend = ((currentBids[highestBidder] - unsettledPayouts ) * sale_fee) / bid_Decimals;
            distributeStakeholdersPayouts(toSend, _newOwner);

            //The remainder of the money is then sent to the seller
            toSend = currentBids[highestBidder] - unsettledPayouts - toSend;
            emit Payout(toSend, TheCryptographLogicV1(myCryptograph).owner(), _newOwner);
            AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(TheCryptographLogicV1(myCryptograph).owner(), _newOwner);
        }

        delete unsettledPayouts; //Reset the payouts

        /*
            Find the new highest bidder
         */

        //Reset our bid related variables
        currentBids[_newOwner] = 0;
        duePayout[_newOwner] = 0;

        //Finding the new highest bidder :
        //Explore the below link of the highest bidder.
        address _linkHighest = BidLinkSimple(bidLinks[highestBidder]).below();

        //Deleting  our link
        delete bidLinks[highestBidder];

        //If the below link exist, then the associated bidder is the next highest bidder
        if(_linkHighest != address(0x0)){
            highestBidder = BidLinkSimple(_linkHighest).bidder();
            BidLinkSimple(_linkHighest).setAbove(address(0x0)); //Our below neighbor is the new highest bidder
        } else {
            //No more bidders : we are cancelling ourselves
            delete highestBidder;
        }


        //Reset the selling price
        sellingPrice = 0;
        emit SellingPriceAdjusted(_newOwner, 0);

        //Actually transfer the cryptograph
        TheCryptographLogicV1(myCryptograph).transfer(_newOwner);

        return 0;
    }

    /// @notice Function used to distribute an arbitrary amount of money among non-bidders
    /// @dev Only callable internally
    /// @param _amount The amount of money to spread
    /// @param _contributor The address of the source of the money
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

        //Pay the thirdParty account
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
        //This also somewhat limit the hardcap for a reward to max_UInt256/10^11 => Not a problem as this amount of eth will not be minted
        uint256 decimaledRatio = ((bid_Decimals * bid_multiplier * (_newBid - baseBid) ) / baseBid) + bid_incMin * bid_Decimals;

        //If we go over the maximum payout, we set the reward to the maximum payout
        if(decimaledRatio > (bid_Decimals * bid_incMax)){
            decimaledRatio = bid_Decimals * bid_incMax;
        }

        duePayout[_bidder] = (_newBid * decimaledRatio)/(bid_Decimals*bid_Decimals);
    }

    /// @notice resetting an auction starting in two weeks with the initial auction parameters. No changes to the existing bids.
    /// @dev Only callable by our own cryptograph
    function renatus() external{

        require(msg.sender == myCryptograph, "Only callable by the paired Cryptograph");

        delete hammerBlock; //Reset the minimal sale block
        delete hammerTime; //Reset the minmimal sale time
        delete sellingPrice; //Reset the selling price

        //Reset the auction end/start time to be same duration as initial auction but starting in 14 days
        endTime = now + 60*60*24*14 + endTime - startTime;
        startTime = now + 60*60*24*14;

        //Actually transfer the cryptograph 
        TheCryptographLogicV1(myCryptograph).transfer(address(0));
    }

    /// @notice transfer following the ERC2665 standard
    /// @dev Only callable by the auction house
    /// @param _contributor The operator paying the transfer fee
    /// @param _to The address of the new owner
    function transferERC2665(address _contributor, address _to) external payable restrictedToAuctionHouse() {

         if(msg.value != 0){
            //Distributing the transfer fee
            distributeStakeholdersPayouts(msg.value, _contributor);
        }

        //Checking that no auctions are running
        require(hammerTime == 0, "Can't transfer a cryptograph under sale");
   
        //Reset the selling price
        if(sellingPrice != 0){
            sellingPrice = 0;
            emit SellingPriceAdjusted(_contributor, 0);
        }

        //Actually transfer the cryptograph
        TheCryptographLogicV1(myCryptograph).transfer(_to);

        //New owner mean no approval
        isBeingERC2665Approved = false;

    }

    
    /// @notice Approve following the ERC2665
    /// @dev Only callable by the auction house
    /// @param _contributor The operator paying the transfer fee
    /// @param _approvedAddress The address of the new approved address
    function approveERC2665(address _contributor, address _approvedAddress) external payable restrictedToAuctionHouse(){

        if(msg.value != 0){
            //Distributing the transfer fee
            distributeStakeholdersPayouts(msg.value, _contributor);
        }
      

        //Checking that no auctions are running
        require(hammerTime == 0, "Can't approve a cryptograph under sale");

        //Reset the selling price
        if(sellingPrice != 0){
            sellingPrice = 0;
            emit SellingPriceAdjusted(_contributor, 0);
        }
        
        //Checking address approval
        if(_approvedAddress == address(0) || _approvedAddress == TheCryptographLogicV1(myCryptograph).owner()){
            isBeingERC2665Approved = false;
        } else {
            isBeingERC2665Approved = true;
        }

    }

}


