// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./Crowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 immutable private _cap;

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param __cap Max amount of wei to be contributed
     */
    constructor (uint256 __cap) {
        require(__cap > 0, "CappedCrowdsale: cap is 0");
        _cap = __cap;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
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
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual override view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
    }
}

