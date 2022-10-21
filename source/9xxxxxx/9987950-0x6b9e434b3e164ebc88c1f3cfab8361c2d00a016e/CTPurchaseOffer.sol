pragma solidity ^0.5.17;

import "./GTTokenInterface.sol";
import "./SafeMath.sol";


/**
 * @title CTPurchaseOffer
 * @dev The CTPurchaseOffer contract helps in creating a purchase offer contract
 */
contract CTPurchaseOffer {

    // Struct Offer to define parameters for the purchase offer
    struct Offer {
        address buyer;
        address seller;
        uint gtAmount;
        string companyTokenName;
        uint companyTokenAmount;
        bool active;
        bool completed;
    }

    // Event to be emitted when purchase offer is withdrawn
    event WithdrawPurchaseOffer(address indexed buyerAddress);

    using SafeMath for uint256;

    GTTokenInterface public tokenController;
    Offer public offer;

    /**
     * @dev Constructor, sets the defining parameters for the company token purchase contract by the buyer
     */
    constructor(
        address gtTokenAddress,
        address seller,
        uint gtAmount,
        string memory companyTokenName,
        uint companyTokenAmount
    )
        public
    {
        require(gtTokenAddress != address(0x0));
        tokenController = GTTokenInterface(gtTokenAddress);

        require(tokenController.isInvestorRegistered(msg.sender));
        require(tokenController.isInvestorRegistered(seller));
        require(companyTokenAmount > 0);

        require(tokenController.balanceOf(msg.sender) >= gtAmount);

        offer = Offer(
            msg.sender,
            seller,
            gtAmount,
            companyTokenName,
            companyTokenAmount,
            false,
            false
        );
    }

    modifier onlyTokenContract() {
        require(msg.sender == address(tokenController));
        _;
    }

    function getSeller() external view returns(address) {
        return offer.seller;
    }

    function getBuyer() external view returns(address) {
        return offer.buyer;
    }

    function isOfferCompleted() external view returns(bool) {
        return offer.completed;
    }

    function isOfferActive() external view returns(bool) {
        return offer.active;
    }

    function getCompanyTokenName() external view returns(string memory) {
        return offer.companyTokenName;
    }

    function getCompanyTokenAmount() external view returns(uint) {
        return offer.companyTokenAmount;
    }

    function getGTAmount() external view returns(uint) {
        return offer.gtAmount;
    }

    /**
     * @dev Allows activation of purchase offer contract by the buyer.
     * Can only be called from GT Token contract
     */
    function activateOffer() external onlyTokenContract {
        offer.active = true;
    }

    /**
     * @dev Allows withdrawal of purchase offer contract by the buyer.
     * Can only be called by the buyer or the seller
     */
    function withdrawOffer() external {
        require(offer.buyer == msg.sender || offer.seller == msg.sender);
        require(offer.active);

        tokenController.transfer(offer.buyer, offer.gtAmount);
        offer.active = false;

        emit WithdrawPurchaseOffer(address(this));
    }

    /**
     * @dev Allows acceptance of purchase offer contract by the seller.
     * Can only be caller from GT Token contract
     */
    function acceptOffer() external onlyTokenContract {
        uint fee = (offer.gtAmount).div(100);

        tokenController.transfer(offer.seller, (offer.gtAmount).sub(fee));
        tokenController.burnTokens(fee);

        offer.active = false;
        offer.completed = true;
    }
}

