// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title BidLink Ordered Data Structure (no bidAmount)
/// @notice Classical double linked array data structure that allow us to not have to sort() stuff at the cost of instancing more + proper maintenance
contract BidLinkSimple{

    address public auction; //The Minting auction the BidLink is associated with
    address public bidder; //Our bidder
    address public above;  //BidLink with a bigger bid
    address public below;  //BidLink with a smaller bid

    modifier restrictedToAuction(){
        require((msg.sender == auction), "Only the auction contract can call this function");
        _;
    }

    constructor (address _bidder) public
    {
        auction = msg.sender;
        bidder = _bidder;
    }

    //Function used to reset and reuse a link rather than having to reinstance its bytecode
    function reset(address _bidder) external restrictedToAuction(){
        delete above;
        delete below;
        bidder = _bidder;
    }

    function setAbove(address _above) external restrictedToAuction(){
        above = _above;
    }

    function setBelow(address _below) external restrictedToAuction(){
        below = _below;
    }

}

