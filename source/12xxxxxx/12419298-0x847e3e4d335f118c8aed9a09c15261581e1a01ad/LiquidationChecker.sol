pragma solidity ^0.4.24;

import "./EIP20Interface.sol";
import "./PriceOracleProxy.sol";
import "./MoneyMarket.sol";

contract LiquidationChecker {
    MoneyMarket public moneyMarket;
    address public liquidator;
    bool public allowLiquidation;

    constructor(address moneyMarket_, address liquidator_) public {
        moneyMarket = MoneyMarket(moneyMarket_);
        liquidator = liquidator_;
        allowLiquidation = false;
    }

    function isAllowed(address asset, uint newCash) internal view returns(bool) {
        return allowLiquidation || !isLiquidate(asset, newCash);
    }

    function isLiquidate(address asset, uint newCash) internal view returns(bool) {
        return cashIsUp(asset, newCash) && oracleTouched();
    }

    function cashIsUp(address asset, uint newCash) internal view returns(bool) {
        uint oldCash = EIP20Interface(asset).balanceOf(moneyMarket);

        return newCash >= oldCash;
    }

    function oracleTouched() internal view returns(bool) {
        PriceOracleProxy oracle = PriceOracleProxy(moneyMarket.oracle());

        bool sameOrigin = oracle.mostRecentCaller() == tx.origin;
        bool sameBlock = oracle.mostRecentBlock() == block.number;

        return sameOrigin && sameBlock;
    }

    function setAllowLiquidation(bool allowLiquidation_) public {
        require(msg.sender == liquidator, "LIQUIDATION_CHECKER_INVALID_LIQUIDATOR");

        allowLiquidation = allowLiquidation_;
    }
}

