pragma solidity ^0.4.24;

import "./EIP20Interface.sol";
import "./MoneyMarket.sol";
import "./PriceOracleProxy.sol";

/**
  * @title LiquidationChecker
  * @author Compound
  */
contract LiquidationChecker {
    MoneyMarket public moneyMarket;
    address public liquidator;
    bool public allowLiquidation;

    constructor(address moneyMarket_, address liquidator_) public {
        moneyMarket = MoneyMarket(moneyMarket_);
        liquidator = liquidator_;
        allowLiquidation = false;
    }

    function isAllowed(address asset, uint newCash, uint newBorrows) internal returns(bool) {
        return ( allowLiquidation || !isLiquidate(asset, newCash) ) && !isBorrow(asset, newCash, newBorrows);
    }

    function isBorrow(address asset, uint newCash, uint newBorrows) internal returns(bool) {
        return cashIsDown(asset, newCash) && borrowsUp(asset, newBorrows);
    }

    function isLiquidate(address asset, uint newCash) internal returns(bool) {
        return cashIsUp(asset, newCash) && oracleTouched();
    }

    function cashIsUp(address asset, uint newCash) internal view returns(bool) {
        uint oldCash = EIP20Interface(asset).balanceOf(moneyMarket);

        return newCash >= oldCash;
    }

    function cashIsDown(address asset, uint newCash) internal view returns(bool) {
        uint oldCash = EIP20Interface(asset).balanceOf(moneyMarket);

        return newCash < oldCash;
    }

    function borrowsUp(address asset, uint newBorrows) internal view returns(bool) {
        uint totalBorrows;

        (,,,,,,totalBorrows,,) = moneyMarket.markets(asset);

        return totalBorrows < newBorrows;
    }

    function oracleTouched() internal returns(bool) {
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
