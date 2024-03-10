/* SPDX-License-Identifier: LGPL-3.0-or-later */
pragma solidity ^0.7.0;

import "./Admin.sol";
import "./Exponential.sol";

import "./FintrollerInterface.sol";
import "./FyTokenInterface.sol";
import "./ChainlinkOperatorInterface.sol";

/**
 * @notice Fintroller
 * @author Hifi
 * @notice Controls the financial permissions and risk parameters for all fyTokens.
 */
contract Fintroller is
    FintrollerInterface, /* one dependency */
    Admin /* two dependencies */
{
    /* solhint-disable-next-line no-empty-blocks */
    constructor() Admin() {
        /* Set a default value of 110% for the liquidation incentive. */
        liquidationIncentiveMantissa = 1.1e18;
    }

    /**
     * CONSTANT FUNCTIONS
     */

    /**
     * @notice Reads the storage properties of the bond.
     * @dev It is not an error to provide an invalid fyToken address. The returned values would all be zero.
     * @param fyToken The address of the bond contract.
     */
    function getBond(FyTokenInterface fyToken)
        external
        view
        override
        returns (
            uint256 collateralizationRatioMantissa,
            uint256 debtCeiling,
            bool isBorrowAllowed,
            bool isDepositCollateralAllowed,
            bool isLiquidateBorrowAllowed,
            bool isListed,
            bool isRedeemFyTokenAllowed,
            bool isRepayBorrowAllowed,
            bool isSupplyUnderlyingAllowed
        )
    {
        collateralizationRatioMantissa = bonds[fyToken].collateralizationRatio.mantissa;
        debtCeiling = bonds[fyToken].debtCeiling;
        isBorrowAllowed = bonds[fyToken].isBorrowAllowed;
        isDepositCollateralAllowed = bonds[fyToken].isDepositCollateralAllowed;
        isLiquidateBorrowAllowed = bonds[fyToken].isLiquidateBorrowAllowed;
        isListed = bonds[fyToken].isListed;
        isRedeemFyTokenAllowed = bonds[fyToken].isRedeemFyTokenAllowed;
        isRepayBorrowAllowed = bonds[fyToken].isRepayBorrowAllowed;
        isSupplyUnderlyingAllowed = bonds[fyToken].isSupplyUnderlyingAllowed;
    }

    /**
     * @notice Reads the collateralization ratio of the given bond.
     * @dev It is not an error to provide an invalid fyToken address.
     * @param fyToken The address of the bond contract.
     * @return The collateralization ratio as a mantissa, or zero if an invalid address was provided.
     */
    function getBondCollateralizationRatio(FyTokenInterface fyToken) external view override returns (uint256) {
        return bonds[fyToken].collateralizationRatio.mantissa;
    }

    /**
     * @notice Reads the debt ceiling of the given bond.
     * @dev It is not an error to provide an invalid fyToken address.
     * @param fyToken The address of the bond contract.
     * @return The debt ceiling as a uint256, or zero if an invalid address was provided.
     */
    function getBondDebtCeiling(FyTokenInterface fyToken) external view override returns (uint256) {
        return bonds[fyToken].debtCeiling;
    }

    /**
     * @notice Check if the account should be allowed to borrow fyTokens.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getBorrowAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isBorrowAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to deposit collateral.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getDepositCollateralAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isDepositCollateralAllowed;
    }

    /**
     * @notice Check if the account should be allowed to liquidate fyToken borrows.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getLiquidateBorrowAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isLiquidateBorrowAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to redeem the underlying asset from the Redemption Pool.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getRedeemFyTokensAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isRedeemFyTokenAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to repay borrows.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getRepayBorrowAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isRepayBorrowAllowed;
    }

    /**
     * @notice Checks if the account should be allowed to the supply underlying asset to the Redemption Pool.
     * @dev The bond must be listed.
     * @param fyToken The bond to make the check against.
     * @return bool true = allowed, false = not allowed.
     */
    function getSupplyUnderlyingAllowed(FyTokenInterface fyToken) external view override returns (bool) {
        Bond memory bond = bonds[fyToken];
        require(bond.isListed, "ERR_BOND_NOT_LISTED");
        return bond.isSupplyUnderlyingAllowed;
    }

    /**
     * NON-CONSTANT FUNCTIONS
     */

    /**
     * @notice Marks the bond as listed in this Fintroller's registry. It is not an error to list a bond twice.
     *
     * @dev Emits a {ListBond} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The fyToken must pass the inspection.
     *
     * @param fyToken The fyToken contract to list.
     * @return bool true = success, otherwise it reverts.
     */
    function listBond(FyTokenInterface fyToken) external override onlyAdmin returns (bool) {
        require(fyToken.isFyToken(), "ERR_LIST_BOND_FYTOKEN_INSPECTION");
        bonds[fyToken] = Bond({
            collateralizationRatio: Exp({ mantissa: defaultCollateralizationRatioMantissa }),
            debtCeiling: 0,
            isBorrowAllowed: true,
            isDepositCollateralAllowed: true,
            isLiquidateBorrowAllowed: true,
            isListed: true,
            isRedeemFyTokenAllowed: true,
            isRepayBorrowAllowed: true,
            isSupplyUnderlyingAllowed: true
        });
        emit ListBond(admin, fyToken);
        return true;
    }

    /**
     * @notice Updates the bond's collateralization ratio.
     *
     * @dev Emits a {SetBondCollateralizationRatio} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     * - The new collateralization ratio cannot be higher than the maximum collateralization ratio.
     * - The new collateralization ratio cannot be lower than the minimum collateralization ratio.
     *
     * @param fyToken The bond for which to update the collateralization ratio.
     * @param newCollateralizationRatioMantissa The new collateralization ratio as a mantissa.
     * @return bool true = success, otherwise it reverts.
     */
    function setBondCollateralizationRatio(FyTokenInterface fyToken, uint256 newCollateralizationRatioMantissa)
        external
        override
        onlyAdmin
        returns (bool)
    {
        /* Checks: bond is listed. */
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");

        /* Checks: new collateralization ratio is within the accepted bounds. */
        require(
            newCollateralizationRatioMantissa <= collateralizationRatioUpperBoundMantissa,
            "ERR_SET_BOND_COLLATERALIZATION_RATIO_UPPER_BOUND"
        );
        require(
            newCollateralizationRatioMantissa >= collateralizationRatioLowerBoundMantissa,
            "ERR_SET_BOND_COLLATERALIZATION_RATIO_LOWER_BOUND"
        );

        /* Effects: update storage. */
        uint256 oldCollateralizationRatioMantissa = bonds[fyToken].collateralizationRatio.mantissa;
        bonds[fyToken].collateralizationRatio = Exp({ mantissa: newCollateralizationRatioMantissa });

        emit SetBondCollateralizationRatio(
            admin,
            fyToken,
            oldCollateralizationRatioMantissa,
            newCollateralizationRatioMantissa
        );

        return true;
    }

    /**
     * @notice Updates the debt ceiling, which limits how much debt can be created in the bond market.
     *
     * @dev Emits a {SetBondDebtCeiling} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     * - The debt ceiling cannot be zero.
     * - The debt ceiling cannot fall below the current total supply of fyTokens.
     *
     * @param fyToken The bond for which to update the debt ceiling.
     * @param newDebtCeiling The uint256 value of the new debt ceiling, specified in the bond's decimal system.
     * @return bool true = success, otherwise it reverts.
     */
    function setBondDebtCeiling(FyTokenInterface fyToken, uint256 newDebtCeiling)
        external
        override
        onlyAdmin
        returns (bool)
    {
        /* Checks: bond is listed. */
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");

        /* Checks: the zero edge case. */
        require(newDebtCeiling > 0, "ERR_SET_BOND_DEBT_CEILING_ZERO");

        /* Checks: above total supply of fyTokens. */
        uint256 totalSupply = fyToken.totalSupply();
        require(newDebtCeiling >= totalSupply, "ERR_SET_BOND_DEBT_CEILING_UNDERFLOW");

        /* Effects: update storage. */
        uint256 oldDebtCeiling = bonds[fyToken].debtCeiling;
        bonds[fyToken].debtCeiling = newDebtCeiling;

        emit SetBondDebtCeiling(admin, fyToken, oldDebtCeiling, newDebtCeiling);

        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a borrow.
     *
     * @dev Emits a {SetBorrowAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setBorrowAllowed(FyTokenInterface fyToken, bool state) external override onlyAdmin returns (bool) {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isBorrowAllowed = state;
        emit SetBorrowAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a collateral deposit.
     *
     * @dev Emits a {SetDepositCollateralAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setDepositCollateralAllowed(FyTokenInterface fyToken, bool state)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isDepositCollateralAllowed = state;
        emit SetDepositCollateralAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a liquidate borrow.
     *
     * @dev Emits a {SetLiquidateBorrowAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setLiquidateBorrowAllowed(FyTokenInterface fyToken, bool state)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isLiquidateBorrowAllowed = state;
        emit SetLiquidateBorrowAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Sets a new value for the liquidation incentive, which is applicable
     * to all listed bonds.
     *
     * @dev Emits a {SetLiquidationIncentive} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The new liquidation incentive cannot be higher than the maximum liquidation incentive.
     * - The new liquidation incentive cannot be lower than the minimum liquidation incentive.

     * @param newLiquidationIncentiveMantissa The new liquidation incentive as a mantissa.
     * @return bool true = success, otherwise it reverts.
     */
    function setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa)
        external
        override
        onlyAdmin
        returns (bool)
    {
        /* Checks: new collateralization ratio is within the accepted bounds. */
        require(
            newLiquidationIncentiveMantissa <= liquidationIncentiveUpperBoundMantissa,
            "ERR_SET_LIQUIDATION_INCENTIVE_UPPER_BOUND"
        );
        require(
            newLiquidationIncentiveMantissa >= liquidationIncentiveLowerBoundMantissa,
            "ERR_SET_LIQUIDATION_INCENTIVE_LOWER_BOUND"
        );

        /* Effects: update storage. */
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        emit SetLiquidationIncentive(admin, oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return true;
    }

    /**
     * @notice Updates the oracle contract's address saved in storage.
     *
     * @dev Emits a {SetOracle} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The new address cannot be the zero address.
     *
     * @param newOracle The new oracle contract.
     * @return bool true = success, otherwise it reverts.
     */
    function setOracle(ChainlinkOperatorInterface newOracle) external override onlyAdmin returns (bool) {
        require(address(newOracle) != address(0x00), "ERR_SET_ORACLE_ZERO_ADDRESS");
        address oldOracle = address(oracle);
        oracle = newOracle;
        emit SetOracle(admin, oldOracle, address(newOracle));
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the Redemption Pool before a redemption of underlying.
     *
     * @dev Emits a {SetRedeemFyTokensAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setRedeemFyTokensAllowed(FyTokenInterface fyToken, bool state) external override onlyAdmin returns (bool) {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isRedeemFyTokenAllowed = state;
        emit SetRedeemFyTokensAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the fyToken before a repay borrow.
     *
     * @dev Emits a {SetRepayBorrowAllowed} event.
     *
     * Requirements:
     *
     * - The caller must be the admin.
     * - The bond must be listed.
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setRepayBorrowAllowed(FyTokenInterface fyToken, bool state) external override onlyAdmin returns (bool) {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isRepayBorrowAllowed = state;
        emit SetRepayBorrowAllowed(admin, fyToken, state);
        return true;
    }

    /**
     * @notice Updates the state of the permission accessed by the Redemption Pool before a supply of underlying.
     *
     * @dev Emits a {SetSupplyUnderlyingAllowed} event.
     *
     * Requirements:
     * - The caller must be the admin
     *
     * @param fyToken The fyToken contract to update the permission for.
     * @param state The new state to put in storage.
     * @return bool true = success, otherwise it reverts.
     */
    function setSupplyUnderlyingAllowed(FyTokenInterface fyToken, bool state)
        external
        override
        onlyAdmin
        returns (bool)
    {
        require(bonds[fyToken].isListed, "ERR_BOND_NOT_LISTED");
        bonds[fyToken].isSupplyUnderlyingAllowed = state;
        emit SetSupplyUnderlyingAllowed(admin, fyToken, state);
        return true;
    }
}

