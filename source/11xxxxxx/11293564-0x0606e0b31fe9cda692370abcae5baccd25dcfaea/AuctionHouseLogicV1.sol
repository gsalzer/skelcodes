// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./AuctionHouseV1.sol";

import "./CryptographIndexLogicV1.sol";
import "./TheCryptographLogicV1.sol";
import "./SingleAuctionLogicV1.sol";
import "./CryptographFactoryLogicV1.sol";
import "./MintingAuctionLogicV1.sol";
import "./ERC2665LogicV1.sol";
import "./CryptographKYCLogicV1.sol";

/// @author Guillaume Gonnaud 2019
/// @title Auction House Logic Code
/// @notice The main contract used by collectors to Bid on and Trade cyptographs. Abstract this smart contract on the proxy address for interaction.
contract AuctionHouseLogicV1 is VCProxyData, AuctionHouseHeaderV1, AuctionHouseStoragePublicV1 {

    /// @notice Generic constructor, empty
    /// @dev This contract is meant to be used in a delegatecall hence its memory state is irrelevant
    constructor() public
    {
        //Self intialize (nothing)
    }

    //Modifier for functions that require to be called only by the Cryptograph Factory
    modifier restrictedToFactory(){
        require((msg.sender == factory), "Only the Cryptograph Factory smart contract can call this function");
        _;
    }

    /// @notice Generic catch-all function that accept payments to prevent accidental Eth burn.
    /// @dev A receive function is NOT necessary. Your compiler doesn't know better. 
    fallback() external payable {
        pendingWithdrawals[msg.sender] += msg.value;
        emit Deposit(msg.value,msg.sender, msg.sender, msg.sender);
    }

    /// @notice You now have to pay real money to supress compiler warnings
    /// @dev Completely unecessary trashcode that will always get intercepted by the proxy first
    receive() external payable{
        pendingWithdrawals[msg.sender] += msg.value;
        emit Deposit(msg.value,msg.sender, msg.sender, msg.sender);
    }

    /// @notice Init function of the auction house
    /// @dev Callable only once after deployment
    /// @param _factory The address of the CryptographFactory Instance
    /// @param _index The address of the CryptographIndex Instance
    /// @param _ERC2665Lieutenant The address of the ERC2665 Instance
    /// @param _kycContract The address of the KYC contract Instance
    function init(address _factory, address _index, address _ERC2665Lieutenant, address _kycContract) external {
        require((initialized == false), "The Auction House has already been initialized");
        require(_factory != address(0), "_factory should be != 0x0");
        require(_index != address(0), "_index should be != 0x0");
        require(_ERC2665Lieutenant != address(0), "_ERC2665Lieutenant should be != 0x0");
        require(_kycContract != address(0), "_kycContract should be != 0x0");
        
        initialized = true;
        factory = _factory;
        index = _index;
        ERC2665Lieutenant = _ERC2665Lieutenant;
        kycContract = _kycContract;
    }

    /// @notice Send eth and add it to a withdrawal account.
    /// @dev This is how single auctions smart contracts deposit money
    /// @param _account The address of the account to credit with the payable amount
    /// @param _contributor The address of the user wallet from which the money is from
    function addFundsFor(address _account, address _contributor) external payable{
        pendingWithdrawals[_account] += msg.value;
        emit Deposit(msg.value, _account, _contributor, msg.sender);
    }

    /// @notice Withdraw all the eth from msg.sender account
    /// @dev Only way an external account can take away money from the cryptograph ecosystem
    function withdraw() external {

        //Calculating the withdrawn amount
        uint256 amount = pendingWithdrawals[msg.sender];

        //Emptying the account
        pendingWithdrawals[msg.sender] = 0;

        //Firing the event
        emit UserWithdrawal(amount, msg.sender);

        //Finally transferring the money
        msg.sender.transfer(amount);
    }

    /// @notice Place a bid to own a cryptograph
    /// @dev Calling this function is the only way to eventually gain ownership of a cryptograph
    /// @param _cryptographIssue The serial of the Cryptograph you want to bid on
    /// @param _isOfficial True if bidding on an official cryptograph, false if bidding on a community cryptograph
    /// @param _editionSerial If you are bidding on an edition, specify it's specific edition issue # here
    /// @param _newBidAmount The amount of money you want to bid
    /// @param _previousStandingBidAmount Protection against ordonancement attacks. Please indicate what value is currently visible for yourCryptographAuction.highestBidder().
    function bid(
        uint256 _cryptographIssue,
        bool _isOfficial,
        uint256 _editionSerial,
        uint256 _newBidAmount,
        uint256 _previousStandingBidAmount
    ) external payable{

        //KYC
        require(CryptographKYCLogicV1(kycContract).checkKyc(msg.sender, _newBidAmount),
            "Bid above a specific amount requires the bidder to be KYCed");

        //Grabbing the auction
        SingleAuctionLogicV1 _auc = SingleAuctionLogicV1(
            TheCryptographLogicV1(
                CryptographIndexLogicV1(index).getCryptograph(_cryptographIssue, _isOfficial, _editionSerial)
            ).myAuction()
        );

        //The first check being made is that the current highest standing bid match the announced bid the user is bidding on top of
        require(_auc.currentBids(_auc.highestBidder()) == _previousStandingBidAmount,
            "bid not accepted: current highest standing bid is different than the one specified");

        //Credit the full amount paid to the msg.sender account
        pendingWithdrawals[msg.sender] += msg.value;

        //Check that the sender has enough money in his account to bid
        require(pendingWithdrawals[msg.sender] + _auc.currentBids(msg.sender) >= _newBidAmount, "bid not accepted: Not enough ether was sent");

        uint256 toSend = _newBidAmount - _auc.currentBids(msg.sender);

        //Tapping the money from the account
        pendingWithdrawals[msg.sender] -= toSend;

        //Emiting the bidding event first (before the deposit events from payouts start triggering)
        emit UserBid(address(_auc), _newBidAmount, msg.sender);

        //Bidding
        _auc.bid{value: toSend }(_newBidAmount, msg.sender);
    }

    /// @notice Return the highest bid placed on a cryptograph
    /// @dev Easy way to optain the highest current bid for a cryptograph you want to bid on. Can be nested within bid() for unsafe bids that will always go through.
    /// @param _cryptographIssue The serial of the Cryptograph you want to peek highest bid on
    /// @param _isOfficial True if peeking on an official cryptograph, false if peeking on a community cryptograph
    /// @param _editionSerial If you are peeking on an edition, specify it's specific edition issue # here
    function getHighestBid(uint256 _cryptographIssue, bool _isOfficial, uint256 _editionSerial) external view returns(uint256){
        SingleAuctionLogicV1 _auc = SingleAuctionLogicV1(
            TheCryptographLogicV1(
                CryptographIndexLogicV1(index).getCryptograph(_cryptographIssue, _isOfficial, _editionSerial)
            ).myAuction()
        );
        return _auc.currentBids(_auc.highestBidder());
    }

    /// @notice Cancel your bid on a Cryptograph. WARNING : if highest bidder, you might only get a fraction of your money back
    /// @dev During the initial auction or once a sale has been accepted, a highest bidder can't cancel his bid.
    /// @param _cryptographIssue The serial of the Cryptograph you want to cancel bid on
    /// @param _isOfficial True if cancelling bid on an official cryptograph, false if cancelling bid on a community cryptograph
    /// @param _editionSerial If cancelling bid on an edition, specify it's specific edition issue # here
    function cancelBid(uint256 _cryptographIssue, bool _isOfficial, uint256 _editionSerial) external{

        //Grabbing the auction
        SingleAuctionLogicV1 _auc = SingleAuctionLogicV1(
            TheCryptographLogicV1(
                CryptographIndexLogicV1(index).getCryptograph(_cryptographIssue, _isOfficial, _editionSerial)
            ).myAuction()
        );

        //Emitting the cancelBid event before deposit event is triggered
        emit UserCancelledBid(address(_auc), msg.sender);

        //Actually cancel the bid
        _auc.cancelBid(msg.sender);
    }

    /// @notice Win a cryptograph for the highest bidder
    /// @dev Callable by anyone, but should be called by PA for automatisation.
    /// @param _cryptographIssue The issue # of the Cryptograph you want to claim
    /// @param _isOfficial True if claiming an official cryptograph, false if claiming a community cryptograph
    /// @param _editionSerial If claiming an edition, specify it's specific edition issue # here
    function win(uint256 _cryptographIssue, bool _isOfficial, uint256 _editionSerial) external{

        //Grabbing the auction
        TheCryptographLogicV1 _cry = TheCryptographLogicV1(
                CryptographIndexLogicV1(index).getCryptograph(_cryptographIssue, _isOfficial, _editionSerial)
            );

        SingleAuctionLogicV1 _auc = SingleAuctionLogicV1(_cry.myAuction());

        //Emitting the Win event before other events are triggered
        emit UserWin(address(_auc), _auc.currentBids(_auc.highestBidder()), _auc.highestBidder());

        //Update the ERC2665
        ERC2665LogicV1(ERC2665Lieutenant).transferACryptograph(_cry.owner(), _auc.highestBidder(), address(_cry), _auc.currentBids(_auc.highestBidder()));

        //Actually Win the auction and claim the cryptograph
        if(!(_auc.win(_auc.highestBidder()) == 0)){
            CryptographFactoryLogicV1(factory).mintGGBMA(_cryptographIssue, _isOfficial, _auc.highestBidder()); //Minting in the case of GGBMA
            MintingAuctionLogicV1(address(_auc)).distributeBid(_auc.highestBidder()); //Distributing the money
        }
    }

    /// @notice Set a selling price for a cryptograph if you are the owner. Set to 0 if not for sale, a sale is triggered if the selling price is leq than current highest bid.
    /// @dev Only callable by the Cryptograph owner
    /// @param _cryptographIssue The issue of the Cryptograph you want to sell
    /// @param _isOfficial True if selling an official cryptograph, false if selling a community cryptograph
    /// @param _editionSerial If selling an edition, specify its specific edition issue # here
    /// @param _newSellingPrice the new selling price you want to set
    function setSellingPrice(uint256 _cryptographIssue, bool _isOfficial, uint256 _editionSerial, uint256 _newSellingPrice) external{

        //Grabbing the auction
        SingleAuctionLogicV1 _auc = SingleAuctionLogicV1(
            TheCryptographLogicV1(
                CryptographIndexLogicV1(index).getCryptograph(_cryptographIssue, _isOfficial, _editionSerial)
            ).myAuction()
        );

        //Emitting the UserSell event before other events are triggered
        emit UserSellingPriceAdjust(address(_auc), _newSellingPrice);

        //Actually adjust the selling price
        _auc.setSellingPrice(msg.sender, _newSellingPrice);
    }

    /// @notice Call an ERC2665 transfer on a cryptograph
    /// @dev Only callable by the ERC2665 contract
    /// @param _cryptograph The address of the cryptograph getting transferred
    /// @param _contributor The address of the transfer fee payer
    /// @param _to The address of the new cryptograph owner
    function transferERC2665(address _cryptograph, address _contributor, address _to) external payable{
        require(msg.sender == ERC2665Lieutenant, "Only the ERC2665Lieutenant can call this function");
        SingleAuctionLogicV1(TheCryptographLogicV1(_cryptograph).myAuction()).transferERC2665{value:msg.value}(_contributor, _to);
    }

    /// @notice Call an ERC2665 Approve on a cryptograph
    /// @dev Only callable by the ERC2665 contract
    /// @param _cryptograph The address of the cryptograph getting transferred
    /// @param _contributor The address of the transfer fee payer
    /// @param _approvedAddress The address of the potential owner
    function approveERC2665(address _cryptograph, address _contributor, address _approvedAddress) external payable{
        require(msg.sender == ERC2665Lieutenant, "Only the ERC2665Lieutenant can call this function");
        SingleAuctionLogicV1(TheCryptographLogicV1(_cryptograph).myAuction()).approveERC2665{value:msg.value}(_contributor, _approvedAddress);
    }

}


