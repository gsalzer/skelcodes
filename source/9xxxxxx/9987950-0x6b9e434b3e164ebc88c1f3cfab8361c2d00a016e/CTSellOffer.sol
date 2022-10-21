pragma solidity ^0.5.17;

import "./GTTokenInterface.sol";


/**
 * @title CTSellOffer
 * @dev The CTSellOffer contract helps in creating a sell offer contract
 */
contract CTSellOffer {

    // Struct Offer to define parameters for the sell offer
    struct Offer {
        address buyer;
        address seller;
        uint gtAmount;
        string companyTokenName;
        uint companyTokenAmount;
        bool active;
        bool completed;
    }

    GTTokenInterface public tokenController;
    Offer public offer;

    /**
     * @dev Constructor, sets the defining parameters for the company token sell contract by the seller
     */
    constructor(
        address gtTokenAddress,
        address buyer,
        uint gtAmount,
        string memory companyTokenName,
        uint companyTokenAmount
    )
        public
    {
        require(gtTokenAddress != address(0x0));
        tokenController = GTTokenInterface(gtTokenAddress);

        require(tokenController.isInvestorRegistered(msg.sender));
        require(tokenController.isInvestorRegistered(buyer));
        require(gtAmount > 0);

        require(tokenController.getCompanyTokenBalance(companyTokenName, msg.sender) >= companyTokenAmount);

        offer = Offer(
            buyer,
            msg.sender,
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
     * @dev Allows activation of sell offer contract by the seller.
     * Can only be called from GT Token contract
     */
    function activateOffer() external onlyTokenContract {
        offer.active = true;
    }

    /**
     * @dev Allows de-activation of sell offer contract by the seller.
     * Can only be called from GT Token contract
     */
    function deActivateOffer() external onlyTokenContract {
        offer.active = false;
    }

    /**
     * @dev Allows acceptance of sell offer contract by the buyer.
     * Can only be called from GT Token contract
     */
    function acceptOffer() external onlyTokenContract {
        offer.completed = true;
        offer.active = false;
    }
}

