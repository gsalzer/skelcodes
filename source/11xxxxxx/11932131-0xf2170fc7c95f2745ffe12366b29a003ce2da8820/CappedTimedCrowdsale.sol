// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./SafeMath.sol";
import "./TimedCrowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions based on time.
 */
abstract contract CappedTimedCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param capReceived Max amount of wei to be contributed
     */
    constructor (uint256 capReceived) {
        require(capReceived > 0, "CappedCrowdsale: cap is 0");
        _cap = capReceived;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /*
    ** Updates cap
    */
    function changeCap(uint256 newCap) internal {
        _cap = newCap;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed or if the cap has been reached.
     */
    function hasClosed() public view override virtual returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return capReached() || super.hasClosed();
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override virtual view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
    }
}
