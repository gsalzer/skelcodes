// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

/// @author Guillaume Gonnaud 2019
/// @title Auction House Header
/// @notice Contain all the events emitted by the Auction House
contract AuctionHouseHeaderV1 {

    // Deposit: Event emitted whenever money is made available for withdrawal in the Auction House
    // amount: Amount of money being deposited
    // beneficiary: Account that will be able to withdraw the money
    // contributor: Which user wallet initially contributed the received money
    // origin: Which smart contract sent the money
    event Deposit(uint256 indexed amount, address indexed beneficiary, address indexed contributor, address origin);

    // Withdrawal: event emitted whenever a user withdraw his Eth on the auction house smart contract
    // amount: total amount of money withdrawn
    // account: address of user withdrawing his money
    event UserWithdrawal(uint256 indexed amount, address indexed account);

    // Bid: event emitted whenever a user submit a new bid to an auction
    // auction: the address of the auction
    // bidValue: the eth value of the new standing bid
    // bidder: the address of the user who just bid
    event UserBid(address indexed auction, uint256 indexed bidValue, address indexed bidder);

    // CancelBid: event emitted whenever a user manually cancel a bid
    // auction: the address of the auction
    // bidder: the address of the user who just cancelled his bid
    event UserCancelledBid(address indexed auction, address indexed bidder);

    // Win: event emitted whenever a user win an auction
    // auction: the address of the auction
    // bidValue: the eth value of the winning bid
    // bidder: the address of the user who just won the auction his bid
    event UserWin(address indexed auction, uint256 indexed bidValue, address indexed bidder);

    // UserSell: event emitted whenever a user trigger a sale at an auction
    // auction: the address of the auction
    event UserSell(address indexed auction);

    // UserSellingPriceAdjust: event emitted whenever a user adjust the selling price of an auction
    // auction: the address of the auction
    // value : the new adjusted price. 0 for disabled
    event UserSellingPriceAdjust(address indexed auction, uint256 indexed value);
}


/// @author Guillaume Gonnaud 2019
/// @title Auction House Storage Internal
/// @notice Contain all the storage of the auction house declared in a way that does not generate getters for Proxy use
contract AuctionHouseStorageInternalV1 {
    bool internal initialized; //Bool to check if the index have been initialized
    address internal factory; //The factory smart contract (proxy) that will publish the cryptographs
    address internal index; //The index smart contract that maps cryptographs and their auctions
    mapping (address => uint) internal pendingWithdrawals;  //How much money each user owns on the smart contract

    address internal ERC2665Lieutenant;
    address internal kycContract;
}


/// @author Guillaume Gonnaud
/// @title Auction House Storage Public
/// @notice Contain all the storage of the auction house declared in a way that generates getters for Logic Code use
contract AuctionHouseStoragePublicV1 {
    bool public initialized; //Bool to check if the index have been initialized
    address public factory; //The factory smart contract (proxy) that will publish the cryptographs
    address public index; //The index smart contract that maps cryptographs and their auctions
    mapping (address => uint) public pendingWithdrawals;  //How much money each user owns on the smart contract

    address public ERC2665Lieutenant;
    address public kycContract;

}
