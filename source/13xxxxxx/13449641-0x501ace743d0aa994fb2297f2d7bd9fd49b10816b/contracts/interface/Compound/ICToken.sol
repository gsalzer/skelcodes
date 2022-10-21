// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from https://etherscan.io/address/0xa035b9e130f2b1aedc733eefb1c67ba4c503491f#code

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title Compound's CToken Contract
 * @author Compound
 * @notice Abstract base for CTokens
 */
interface ICToken is IERC20Metadata {
    /**
      * @notice Sender borrows assets from the protocol to their own address.
      * @param borrowAmount The amount of the underlying asset to borrow.
      * @return error 0=success, otherwise a failure (see ErrorReporter.sol for details).
      */
    function borrow(uint256 borrowAmount) external returns (uint256 error);

    /**
     * @notice Sender redeems cTokens in exchange for the underlying asset.
     * @dev Accrues interest whether or not the operation succeeds, unless reverted.
     * @param redeemTokens The number of cTokens to redeem into underlying.
     * @return error 0=success, otherwise a failure (see ErrorReporter.sol for details).
     */
    function redeem(uint redeemTokens) external returns (uint256 error);

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken.
     * @dev This function does not accrue interest before calculating the exchange rate.
     * @return rate Calculated exchange rate scaled by 1e18.
     */
    function exchangeRateStored() external view returns (uint256 rate);

    /**
     * @notice Underlying asset for this CToken.
     * Does not exist on CETH.
     */
    function underlying() external view returns (address);

    /**
     * @notice Get the underlying balance of the `owner`.
     * @dev This also accrues interest in a transaction.
     * @param owner The address of the account to query.
     * @return ubalance The amount of underlying owned by `owner`.
     */
    function balanceOfUnderlying(address owner) external returns (uint256 ubalance);
}

