pragma solidity ^0.5.0;
import "./ERC721Full.sol";
import "./AccessControl.sol";

contract BidCVXBX is Ownable, AccessControl, ERC721Full {

    //Bidding Active Status
    bool public bidding = false;

    address constant nullAddress = address(0);

    //Bidding
    struct Offer {
        bool isForSale;
        uint tokenId;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint tokenId;
        address bidder;
        uint value;
    }


    // A record of horses that are offered for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Offer) public horsesOfferedForSale;

    // A record of the highest horse bid
    mapping (uint => Bid) public horseBids;

    mapping (address => uint) public pendingWithdrawals;

    uint public bidSuccessFees = 0; //Fees

    //Bid specific events
    event BiddingPaused( uint64 date );
    event BiddingUnPaused( uint64 date );

    event HorseOffered(uint indexed tokenId, uint minValue, address toAddress, uint64 time );
    event HorseBidEntered(uint indexed tokenId, uint value, address indexed fromAddress, uint64 time);
    event HorseBidWithdrawn(uint indexed tokenId, uint value, address indexed fromAddress, uint64 time);
    event HorseBoughtWithBid(uint indexed tokenId, uint value, address indexed fromAddress, address indexed toAddress, uint64 time);
    event HorseBoughtWithOffer(uint indexed tokenId, uint value, address indexed fromAddress, address indexed toAddress, uint64 time);
    event HorseNoLongerForSale(uint indexed tokenId, uint64 time);

    modifier whenBiddingActive() {
        require(bidding, 'Bidding is currently not active!');
        _;
    }

    modifier whenBiddingNotActive() {
        require(!bidding, 'Bidding is currently active!');
        _;
    }

    modifier onlyTokenOwner( uint tokenId ) {
        require( ownerOf(tokenId) == msg.sender, 'Only owners of horse can call this!' );
        _;
    }

    modifier onlyNonTokenOwner( uint tokenId ) {
        require( ownerOf(tokenId) != msg.sender && ownerOf(tokenId) != nullAddress, 'Non owners of this horse can call this!' );
        _;
    }

    constructor () public { }

    //Bidding Utilities
    /**
    * @dev called by the owner to pause, triggers stopped state of bidding
    */
   function pauseBidding() public onlyCOO whenBiddingActive returns (bool) {
      bidding = false;
      emit BiddingPaused( uint64(now) );
      return true;
   }

   /**
   * @dev called by the owner to unpause, returns to normal state of bidding
   */
    function unpauseBidding() public onlyCOO whenBiddingNotActive returns (bool) {
      bidding = true;
      emit BiddingUnPaused( uint64(now) );
      return true;
    }

    function horseNoLongerForSale(uint tokenId) public whenNotPaused whenBiddingActive onlyTokenOwner(tokenId) {
        horsesOfferedForSale[tokenId] = Offer(false, tokenId, msg.sender, 0, nullAddress);
        emit HorseNoLongerForSale(tokenId, uint64(now));
    }

    function offerHorseForSale(uint tokenId, uint minSalePriceInWei) public whenNotPaused whenBiddingActive onlyTokenOwner(tokenId) {
        horsesOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, nullAddress);
        emit HorseOffered(tokenId, minSalePriceInWei, nullAddress, uint64(now) );
    }

    function offerHorseForSaleToAddress(uint tokenId, uint minSalePriceInWei, address toAddress) public whenNotPaused whenBiddingActive onlyTokenOwner(tokenId) {
        horsesOfferedForSale[tokenId] = Offer(true, tokenId, msg.sender, minSalePriceInWei, toAddress);
        emit HorseOffered(tokenId, minSalePriceInWei, toAddress, uint64(now));
    }

    function buyHorseFromOffer(uint tokenId) public whenNotPaused whenBiddingActive payable {
        Offer memory offer = horsesOfferedForSale[tokenId];
        require( offer.isForSale, 'This horse if not for sale!' );
        require( offer.onlySellTo == nullAddress || offer.onlySellTo == msg.sender, "Horse not supposed to be sold to this user!" );
        require( msg.value >= offer.minValue, "Didn't send enough ETH to buy Horse" );
        require( offer.seller == ownerOf(tokenId), "Seller no longer owner of horse" );

        address seller = offer.seller;

        //Transfer horse to new owner
        transferFromOffer( seller, msg.sender, tokenId );

        horseNoLongerForSale( tokenId );
        pendingWithdrawals[seller] += msg.value;

        emit HorseBoughtWithOffer(tokenId, msg.value, seller, msg.sender, uint64(now));

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = horseBids[tokenId];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            horseBids[tokenId] = Bid(false, tokenId, nullAddress, 0);
        }

       deductFees( seller, msg.value ); //Transfer funds
    }

    function enterBidForHorse(uint tokenId) public whenNotPaused whenBiddingActive onlyNonTokenOwner(tokenId) payable {
        Bid memory existing = horseBids[tokenId];
        require (msg.value > existing.value, "Bid value cannot be less than or equal to existing value!");

        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        horseBids[tokenId] = Bid(true, tokenId, msg.sender, msg.value);
        emit HorseBidEntered(tokenId, msg.value, msg.sender, uint64(now));
    }

    function acceptBidForHorse(uint tokenId, uint minPrice) public whenNotPaused whenBiddingActive onlyTokenOwner( tokenId ) {
        address seller = msg.sender;
        Bid memory bid = horseBids[tokenId];
        require( bid.value > 0 && bid.value >= minPrice, "Bid value should be greater than or equal to minPrice!" );

        //Transfer horse to new owner
        transferFromOffer( seller, bid.bidder, tokenId );

        horsesOfferedForSale[tokenId] = Offer(false, tokenId, bid.bidder, 0, nullAddress);
        uint amount = bid.value;
        horseBids[tokenId] = Bid(false, tokenId, nullAddress, 0);
        pendingWithdrawals[seller] += amount;

        emit HorseBoughtWithBid(tokenId, bid.value, seller, bid.bidder, uint64(now));

        deductFees(seller, amount); //Transfer funds
    }

    function withdrawBidForHorse(uint tokenId) public whenNotPaused whenBiddingActive onlyNonTokenOwner(tokenId) {
        Bid memory bid = horseBids[tokenId];
        require( bid.bidder == msg.sender, 'Only Bidders can withdraw their bids!' );
        emit HorseBidWithdrawn(tokenId, bid.value, msg.sender, uint64(now));
        uint amount = bid.value;
        horseBids[tokenId] = Bid(false, tokenId, nullAddress, 0);

        // Refund the bid money
        msg.sender.transfer(amount);
    }


    function setSuccessFees( uint256 fees ) public onlyCFO {
      bidSuccessFees = fees;
    }

    function calcFees( uint _amount ) internal view returns(uint) {
        uint fees = (_amount * bidSuccessFees)/100;
        return fees;
    }
    
    function deductFees( address seller, uint amount ) private {
        uint fees = calcFees( amount );
        if( fees > 0 ) {
            cfoAddress.transfer(fees);
            pendingWithdrawals[ seller ] = pendingWithdrawals[ seller ] - fees;
        }
    }

    function withdrawFundsFromBid() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }

}

