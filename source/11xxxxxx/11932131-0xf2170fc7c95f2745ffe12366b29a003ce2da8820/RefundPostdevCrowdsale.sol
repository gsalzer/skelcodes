// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;
import "./RefundableCrowdsale.sol";
import "./PostDeliveryCrowdsale.sol";


/**
 * @title RefundablePostDeliveryCrowdsale
 * @dev Extension of RefundableCrowdsale contract that only delivers the tokens
 * once the crowdsale has closed and the goal met, preventing refunds to be issued
 * to token holders.
 */
abstract contract RefundablePostDeliveryCrowdsale is RefundableCrowdsale, PostDeliveryCrowdsale {

    function _forwardFunds() internal override(CrowdsaleMint,RefundableCrowdsale) virtual {
        RefundableCrowdsale._forwardFunds();
    }

    function _processPurchase(address beneficiary, uint256 tokenAmount) internal override(CrowdsaleMint, PostDeliveryCrowdsale) virtual {
        PostDeliveryCrowdsale._processPurchase(beneficiary, tokenAmount);
    }

    function withdrawTokens(address beneficiary) override virtual public {
        require(finalized(), "RefundablePostDeliveryCrowdsale: not finalized");
        require(goalReached(), "RefundablePostDeliveryCrowdsale: goal not reached");

        super.withdrawTokens(beneficiary);
    }
}
