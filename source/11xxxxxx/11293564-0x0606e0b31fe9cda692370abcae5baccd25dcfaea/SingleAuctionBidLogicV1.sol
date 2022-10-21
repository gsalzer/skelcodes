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
/// @title Single Auction Bid Logic Code
/// @notice Implements a GBM auction bid function. See white paper for the details. Logic code, to be casted on a proxy.
contract SingleAuctionBidLogicV1 is VCProxyData, SingleAuctionHeaderV1, SingleAuctionStorageInternalV1  {

    //Modifier for functions that requires to be called only by the Auction house
    modifier restrictedToAuctionHouse(){
        require((msg.sender == auctionHouse), "Only the auction house smart contract can call this function");
        _;
    }


    /// @notice Place a bid to own a cryptograph and distribute the incentives
    /// @dev Only callable by the Auction House
    /// @param _newBidAmount The amount of the new bid
    /// @param _newBidder The address of the bidder
    function bid(uint256 _newBidAmount, address _newBidder) external payable restrictedToAuctionHouse(){

        /*
        ========================== money check ==========================
        */

        //uninitialized  cryptographs can't be bid upon
        require(initialized, "This auction has not been properly setup yet");

        //Did we send the proper amount of money ?
        require(_newBidAmount == msg.value + currentBids[_newBidder], "Amount of money sent incorrect");

        //check to be made : is the new bid big enough ?
        require( //Either fresh bid or meeting the standing bid * the step
            ((highestBidder == address(0)) && startingPrice <= _newBidAmount) ||
            ( (highestBidder != address(0)) && (currentBids[highestBidder] * (bid_Decimals + bid_stepMin) <= (_newBidAmount * bid_Decimals) )),
            "New bid amount does not meet the minimal new bid amount");

        /*
        ========================== Timing check ==========================
        */

        //We must be past the initial auction start
        require(now >= startTime, "You can only bid once the initial auction has started");

        //Checking if an auction is not over
        require((now < endTime && TheCryptographLogicV1(myCryptograph).owner() == address(0x0)) ||
        (TheCryptographLogicV1(myCryptograph).owner() != address(0x0) && (hammerTime == 0 || now < hammerTime)),
        "The auction is over, the bid was rejected");

        //Extending the time at the end of the initial auction
        if(endTime < now + 600 && TheCryptographLogicV1(myCryptograph).owner() == address(0x0)){
            endTime = now + 600;
        }

        //If hammer time is non-zero, we must be before the end of hammerTime
        //This allow potential bidders to come in.
        if(hammerTime != 0 && now + 600 > hammerTime){
            hammerTime = now + 600; //Extend the hammertime auction by 600s
            hammerBlock = block.number + 4; //Extend the number of minimum elapsed block by 4
        }


        //Emit the bid acceptance event before triggering the payouts
        emit BidAccepted(_newBidAmount, _newBidder);

        /*
        ========================== Payouts ==========================
        */

        //0.5% of the bid is sent to third parties
        uint256 duePay;

        //The first bid in perpetual trading is exempted from bidding fees
        if(!(highestBidder == address(0) && TheCryptographLogicV1(myCryptograph).owner() != address(0))){
            //If not, a bidding fee is taken and distrubuted
            duePay = (_newBidAmount * bid_cutOthers)/bid_Decimals;
            unsettledPayouts += duePay;
            distributeStakeholdersPayouts(duePay, _newBidder);
        }

        //Send his payout to the previous highest bidder
        duePay = duePayout[highestBidder];
        if(duePay != 0){
            unsettledPayouts += duePay;
            emit Payout(duePay,  highestBidder,  _newBidder);
            AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: duePay }(highestBidder, _newBidder);
        }

        /*
        ========================== Reward ==========================
        */

        //Set the new payout amount we will receive when outbid
        calculateReward(_newBidAmount, _newBidder);

        /*
        ===================== Bid Cancellation =====================
        */
        uint256 toSend;

        if ( hammerTime != 0 || TheCryptographLogicV1(myCryptograph).owner() == address(0)) { //Ongoing sale
            
            if(highestBidder != _newBidder){
                //We cancel and withdraw the current highest standing bid
                toSend = currentBids[highestBidder];
                if(toSend != 0){ //For the case of the first ever bid on an auction : address 0x0 is not cancelling anything...
                    //Send back all the money : no payout settlement required
                    emit BidCancelled(toSend, toSend, highestBidder);
                    AuctionHouseLogicV1(address(uint160(auctionHouse))).addFundsFor{value: toSend }(highestBidder, highestBidder);
                    //Edge case because of renatus : we may have a link of bids to maintain, so no reseting links
                    delete currentBids[highestBidder];
                    delete duePayout[highestBidder];
                }
            }
        }

            
        if(currentBids[_newBidder] != 0){
            emit BidCancelled(currentBids[_newBidder], 0, _newBidder);
            //No need to send any back money to a self outbidder : this smart contract only receive the extra required amount

            //Updating our neigbors link
            if( BidLinkSimple(bidLinks[_newBidder]).above() != address(0x0)){
                  BidLinkSimple(BidLinkSimple(bidLinks[_newBidder]).above()).setBelow(BidLinkSimple(bidLinks[_newBidder]).below()); //Unlinking above us
            }

            //We don't need to update the link below us if we are already the highest bidder
            if(highestBidder != _newBidder){
                if( BidLinkSimple(bidLinks[_newBidder]).below() != address(0x0)){
                    BidLinkSimple(BidLinkSimple(bidLinks[_newBidder]).below()).setAbove(BidLinkSimple(bidLinks[_newBidder]).above()); //Unlinking below us
                }
            }
        }
        

        /*
        ===================== Bid Registering =====================
        */

        //Check if the bidder already had a link. Create one if not
        if(bidLinks[_newBidder] == address(0x0)){
            bidLinks[_newBidder] = address(new BidLinkSimple(_newBidder));
        }

        //Link our bidlink to the previous head, if it's not already us (which would mean no changes)
        if(_newBidder != highestBidder){

            //There is no one above us
            BidLinkSimple(bidLinks[_newBidder]).setAbove(address(0x0));

            if( hammerTime == 0 && TheCryptographLogicV1(myCryptograph).owner() != address(0)){ //We did not cancel the previous highest bidder
                //The Link below us is the previous highest bidder
                BidLinkSimple(bidLinks[_newBidder]).setBelow(bidLinks[highestBidder]);

                //We are above the link below us
                if(highestBidder != address(0x0)){
                    BidLinkSimple(bidLinks[highestBidder]).setAbove(bidLinks[_newBidder]);
                }

            } else { //We just cancelled the previous highest bidder

                //If said highest bidder existed
                if(highestBidder != address(0x0)){

                    //The bid below us is the bid that is currently below the still registered previous highest bidder
                    BidLinkSimple(bidLinks[_newBidder]).setBelow(BidLinkSimple(bidLinks[highestBidder]).below());

                    //We are also above said bid
                    if(BidLinkSimple(bidLinks[highestBidder]).below() != address(0x0)){
                       BidLinkSimple(BidLinkSimple(bidLinks[highestBidder]).below()).setAbove(bidLinks[_newBidder]);
                    }


                } else {
                    //There is no one below us
                    BidLinkSimple(bidLinks[_newBidder]).setBelow(address(0x0));
                }
            }
        }

        //Set the amount of the new highest bid
        currentBids[_newBidder] = _newBidAmount;
        highestBidder = _newBidder; //We are the new highest bidder

        /*
        ===================== Sales Trigger =====================
        */

        //If a selling price have been met, trigger a sale
        if( sellingPrice != 0 && _newBidAmount >= sellingPrice && hammerTime == 0){
            hammerTime = now + hammerTimeDuration;
            hammerBlock = block.number + hammerBlockDuration;
            emit SaleStarted(_newBidder, hammerTime, hammerBlock);
        }
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

}


