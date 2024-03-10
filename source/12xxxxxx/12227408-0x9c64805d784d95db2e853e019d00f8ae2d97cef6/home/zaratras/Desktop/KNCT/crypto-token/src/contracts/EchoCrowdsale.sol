// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import './lib/Crowdsale.sol';
import './lib/CappedCrowdsale.sol';
import './lib/TimedCrowdsale.sol';
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Echo Token Crowdsale
 * @dev This is the Echo Token crowdsale.
 */
contract EchoCrowdsale is Crowdsale, CappedCrowdsale, TimedCrowdsale {
    using SafeMath for uint256;

    //minimum investor Contribution
	uint256 public investorMinCap;

    //maximum investor Contribution
	uint256 public investorHardCap;

    mapping(address => uint256) public contributions;

    constructor(
        uint256 rate,
        address payable wallet,
        IERC20Upgradeable token,
        uint256 cap,
        uint256 _investorMinCap,
        uint256 _investorHardCap,
        uint256 openingTime,
        uint256 closingTime
    ) 
    Crowdsale(rate, wallet, token)
    CappedCrowdsale(cap)
    TimedCrowdsale(openingTime, closingTime) {
        investorMinCap = _investorMinCap;
        investorHardCap = _investorHardCap;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal override(Crowdsale, CappedCrowdsale, TimedCrowdsale) view {
        super._preValidatePurchase(_beneficiary, _weiAmount);
        require(!isContract(_beneficiary), "The account has a nonzero code field - it may not be an EOA");
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        require(_newContribution >= investorMinCap && _newContribution <= investorHardCap, "Transaction amount outside acceptable bounds");
    }

    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal override {
        super._updatePurchasingState(_beneficiary, _weiAmount);
        uint256 _existingContribution = contributions[_beneficiary];
        uint256 _newContribution = _existingContribution.add(_weiAmount);
        contributions[_beneficiary] = _newContribution; 
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

}
