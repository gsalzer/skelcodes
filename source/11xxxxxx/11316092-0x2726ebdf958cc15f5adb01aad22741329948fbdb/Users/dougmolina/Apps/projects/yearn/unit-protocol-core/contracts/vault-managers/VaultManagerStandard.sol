// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov (az@unit.xyz).
*/
pragma solidity ^0.7.1;
pragma experimental ABIEncoderV2;

import "../Vault.sol";
import "../helpers/Math.sol";
import "../helpers/ReentrancyGuard.sol";


/**
 * @title VaultManagerStandard
 * @author Unit Protocol: Artem Zakharov (az@unit.xyz), Alexander Ponomorev (@bcngod)
 **/
contract VaultManagerStandard is ReentrancyGuard {
    using SafeMath for uint;

    Vault public immutable vault;

    /**
     * @dev Trigger when params joins are happened
    **/
    event Join(address indexed asset, address indexed user, uint main, uint col, uint usdp);

    /**
     * @dev Trigger when params exits are happened
    **/
    event Exit(address indexed asset, address indexed user, uint main, uint col, uint usdp);

    /**
     * @param _vault The address of the Vault
     **/
    constructor(address payable _vault) public {
        vault = Vault(_vault);
    }

    /**
     * @notice Depositing tokens must be pre-approved to vault address
     * @notice Token using as main collateral must be whitelisted
     * @dev Deposits collaterals
     * @param asset The address of token using as main collateral
     * @param mainAmount The amount of main collateral to deposit
     * @param colAmount The amount of COL token to deposit
     **/
    function deposit(address asset, uint mainAmount, uint colAmount) public nonReentrant {

        // check usefulness of tx
        require(mainAmount != 0 || colAmount != 0, "Unit Protocol: USELESS_TX");

        if (mainAmount != 0) {
            vault.depositMain(asset, msg.sender, mainAmount);
        }

        if (colAmount != 0) {
            vault.depositCol(asset, msg.sender, colAmount);
        }

        // fire an event
        emit Join(asset, msg.sender, mainAmount, colAmount, 0);
    }

    /**
     * @notice COL token must be pre-approved to vault address (if being deposited)
     * @notice Token using as main collateral must be whitelisted
     * @dev Deposits collaterals converting ETH to WETH
     * @param colAmount The amount of COL token to deposit
     **/
    function deposit_Eth(uint colAmount) public payable nonReentrant {

        // check usefulness of tx
        require(msg.value != 0 || colAmount != 0, "Unit Protocol: USELESS_TX");

        if (msg.value != 0) {
            vault.depositEth{value: msg.value}(msg.sender);
        }

        if (colAmount != 0) {
            vault.depositCol(vault.weth(), msg.sender, colAmount);
        }

        // fire an event
        emit Join(vault.weth(), msg.sender, msg.value, colAmount, 0);
    }

    /**
      * @notice Tx sender must have a sufficient USDP balance to pay the debt
      * @dev Repays specified amount of debt
      * @param asset The address of token using as main collateral
      * @param usdpAmount The amount of USDP token to repay
      **/
    function repay(address asset, uint usdpAmount) public nonReentrant {

        // check usefulness of tx
        require(usdpAmount != 0, "Unit Protocol: USELESS_TX");

        _repay(asset, msg.sender, usdpAmount);

        // fire an event
        emit Exit(asset, msg.sender, 0, 0, usdpAmount);
    }

    /**
      * @notice Tx sender must have a sufficient USDP balance to pay the debt
      * @notice USDP approval is NOT needed
      * @dev Repays total debt and withdraws collaterals
      * @param asset The address of token using as main collateral
      * @param mainAmount The amount of main collateral token to withdraw
      * @param colAmount The amount of COL token to withdraw
      **/
    function repayAllAndWithdraw(
        address asset,
        uint mainAmount,
        uint colAmount
    )
    external
    nonReentrant
    {
        uint debtAmount = vault.debts(asset, msg.sender);

        if (mainAmount == 0 && colAmount == 0) {
            // just repay the debt
            return repay(asset, debtAmount);
        }

        if (mainAmount != 0) {
            // withdraw main collateral to the user address
            vault.withdrawMain(asset, msg.sender, mainAmount);
        }

        if (colAmount != 0) {
            // withdraw COL tokens to the user's address
            vault.withdrawCol(asset, msg.sender, colAmount);
        }

        if (debtAmount != 0) {
            // burn USDP from the user's address
            _repay(asset, msg.sender, debtAmount);
        }

        // fire an event
        emit Exit(asset, msg.sender, mainAmount, colAmount, debtAmount);
    }

    /**
      * @notice Tx sender must have a sufficient USDP balance to pay the debt
      * @notice USDP approval is NOT needed
      * @dev Repays total debt and withdraws collaterals
      * @param ethAmount The ETH amount to withdraw
      * @param colAmount The amount of COL token to withdraw
      **/
    function repayAllAndWithdraw_Eth(
        uint ethAmount,
        uint colAmount
    )
    external
    nonReentrant
    {
        uint debtAmount = vault.debts(vault.weth(), msg.sender);

        if (ethAmount == 0 && colAmount == 0) {
            // just repay the debt
            return repay(vault.weth(), debtAmount);
        }

        if (ethAmount != 0) {
            // withdraw ETH to the user address
            vault.withdrawEth(msg.sender, ethAmount);
        }

        if (colAmount != 0) {
            // withdraw COL tokens to the user's address
            vault.withdrawCol(vault.weth(), msg.sender, colAmount);
        }

        if (debtAmount != 0) {
            // burn USDP from the user's address
            _repay(vault.weth(), msg.sender, debtAmount);
        }

        // fire an event
        emit Exit(vault.weth(), msg.sender, ethAmount, colAmount, debtAmount);
    }

    // decreases debt
    function _repay(address asset, address user, uint usdpAmount) internal {
        uint fee = vault.calculateFee(asset, user, usdpAmount);
        vault.chargeFee(vault.usdp(), user, fee);

        // burn USDP from the user's balance
        uint debtAfter = vault.repay(asset, user, usdpAmount);
        if (debtAfter == 0) {
            // clear unused storage
            vault.destroy(asset, user);
        }
    }
}

