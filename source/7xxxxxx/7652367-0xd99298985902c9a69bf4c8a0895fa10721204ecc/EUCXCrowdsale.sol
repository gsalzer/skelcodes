pragma solidity ^0.5.2;

import "./EUCXToken.sol";
import "./Crowdsale.sol";
import "./Ownable.sol";
import "./RefundableCrowdsale.sol";
import "./CappedCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./WhitelistCrowdsale.sol";

contract EUCXCrowdsale is Crowdsale, CappedCrowdsale, TimedCrowdsale, WhitelistCrowdsale, RefundableCrowdsale, Ownable
{
    constructor(address payable wallet, IERC20 token, uint256 openingTime, uint256 closingTime)
        Crowdsale(wallet, token)
        CappedCrowdsale(7500 * uint(10**18))
        TimedCrowdsale(openingTime, closingTime)
        WhitelistCrowdsale()
        RefundableCrowdsale(7500 * uint(10**18))
        FinalizableCrowdsale()
        Ownable()
        public
    {
    }

    function claimRefund(address payable refundee) public
    {
        require(finalized(), "Sale not finalized yet");
        require(!goalReached(), "Goal has been reached");
        require(_escrow.depositsOf(refundee) != 0, "Tokens already withdrawn, forfeited on refund");

        _escrow.withdraw(refundee);
    }
}
