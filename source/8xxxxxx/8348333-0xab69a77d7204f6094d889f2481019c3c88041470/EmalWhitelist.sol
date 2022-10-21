pragma solidity 0.4.24;

import './Ownable.sol';

/** @notice This contract provides support for whitelisting addresses.
 * only whitelisted addresses are allowed to send ether and buy tokens
 * during preSale and Pulic crowdsale.
 * @dev after deploying contract, deploy Presale / Crowdsale contract using
 * EmalWhitelist address. To allow claim refund functionality and allow wallet
 * owner efatoora to send ether to Crowdsale contract for refunds add wallet
 * address to whitelist.
 */
contract EmalWhitelist is Ownable {

    mapping(address => bool) whitelist;

    event AddToWhitelist(address investorAddr);
    event RemoveFromWhitelist(address investorAddr);


    /** @dev Throws if operator is not whitelisted.
     */
    modifier onlyIfWhitelisted(address investorAddr) {
        require(whitelist[investorAddr]);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /** @dev Returns if an address is whitelisted or not
     */
    function isWhitelisted(address investorAddr) public view returns(bool whitelisted) {
        return whitelist[investorAddr];
    }

    /**
     * @dev Adds an investor to whitelist
     * @param investorAddr The address to user to be added to the whitelist, signifies that the user completed KYC requirements.
     */
    function addToWhitelist(address investorAddr) public onlyOwner returns(bool success) {
        require(investorAddr!= address(0));
        whitelist[investorAddr] = true;
        return true;
    }

    /**
     * @dev Removes an investor's address from whitelist
     * @param investorAddr The address to user to be added to the whitelist, signifies that the user completed KYC requirements.
     */
    function removeFromWhitelist(address investorAddr) public onlyOwner returns(bool success) {
        require(investorAddr!= address(0));
        whitelist[investorAddr] = false;
        return true;
    }


}

