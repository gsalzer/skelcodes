pragma solidity ^0.4.24;

import "./EIP20Interface.sol";
import "./EIP20NonStandardInterface.sol";
import "./ErrorReporter.sol";
import "./InterestRateModel.sol";
import "./SafeToken.sol";
import "./MoneyMarket.sol";
import "./LiquidationChecker.sol";

contract Liquidator is ErrorReporter, SafeToken {
    MoneyMarket public moneyMarket;

    constructor(address moneyMarket_) public {
        moneyMarket = MoneyMarket(moneyMarket_);
    }

    event BorrowLiquidated(address targetAccount,
        address assetBorrow,
        uint borrowBalanceBefore,
        uint borrowBalanceAccumulated,
        uint amountRepaid,
        uint borrowBalanceAfter,
        address liquidator,
        address assetCollateral,
        uint collateralBalanceBefore,
        uint collateralBalanceAccumulated,
        uint amountSeized,
        uint collateralBalanceAfter);

    function liquidateBorrow(address targetAccount, address assetBorrow, address assetCollateral, uint requestedAmountClose) public returns (uint) {
        require(targetAccount != address(this), "FAILED_LIQUIDATE_LIQUIDATOR");
        require(targetAccount != msg.sender, "FAILED_LIQUIDATE_SELF");
        require(msg.sender != address(this), "FAILED_LIQUIDATE_RECURSIVE");
        require(assetBorrow != assetCollateral, "FAILED_LIQUIDATE_IN_KIND");

        InterestRateModel interestRateModel;
        (,,interestRateModel,,,,,,) = moneyMarket.markets(assetBorrow);

        require(interestRateModel != address(0), "FAILED_LIQUIDATE_NO_INTEREST_RATE_MODEL");
        require(checkTransferIn(assetBorrow, msg.sender, requestedAmountClose) == Error.NO_ERROR, "FAILED_LIQUIDATE_TRANSFER_IN_INVALID");

        require(doTransferIn(assetBorrow, msg.sender, requestedAmountClose) == Error.NO_ERROR, "FAILED_LIQUIDATE_TRANSFER_IN_FAILED");

        tokenAllowAll(assetBorrow, moneyMarket);

        LiquidationChecker(interestRateModel).setAllowLiquidation(true);

        uint result = moneyMarket.liquidateBorrow(targetAccount, assetBorrow, assetCollateral, requestedAmountClose);

        require(moneyMarket.withdraw(assetCollateral, uint(-1)) == uint(Error.NO_ERROR), "FAILED_LIQUIDATE_WITHDRAW_FAILED");

        LiquidationChecker(interestRateModel).setAllowLiquidation(false);

        // Ensure there's no remaining balances here
        require(moneyMarket.getSupplyBalance(address(this), assetCollateral) == 0, "FAILED_LIQUIDATE_REMAINING_SUPPLY_COLLATERAL"); // just to be sure
        require(moneyMarket.getSupplyBalance(address(this), assetBorrow) == 0, "FAILED_LIQUIDATE_REMAINING_SUPPLY_BORROW"); // just to be sure
        require(moneyMarket.getBorrowBalance(address(this), assetCollateral) == 0, "FAILED_LIQUIDATE_REMAINING_BORROW_COLLATERAL"); // just to be sure
        require(moneyMarket.getBorrowBalance(address(this), assetBorrow) == 0, "FAILED_LIQUIDATE_REMAINING_BORROW_BORROW"); // just to be sure

        // Transfer out everything remaining
        tokenTransferAll(assetCollateral, msg.sender);
        tokenTransferAll(assetBorrow, msg.sender);

        return uint(result);
    }

    function tokenAllowAll(address asset, address allowee) internal {
        EIP20Interface token = EIP20Interface(asset);

        if (token.allowance(address(this), allowee) != uint(-1))
            // require(token.approve(allowee, uint(-1)), "FAILED_LIQUIDATE_ASSET_ALLOWANCE_FAILED");
            require(doApprove(asset, allowee, uint(-1)) == Error.NO_ERROR, "FAILED_LIQUIDATE_ASSET_ALLOWANCE_FAILED");
    }

    function tokenTransferAll(address asset, address recipient) internal {
        uint balance = getBalanceOf(asset, address(this));

        if (balance > 0){
            require(doTransferOut(asset, recipient, balance) == Error.NO_ERROR, "FAILED_LIQUIDATE_TRANSFER_OUT_FAILED");
        }
    }
}

