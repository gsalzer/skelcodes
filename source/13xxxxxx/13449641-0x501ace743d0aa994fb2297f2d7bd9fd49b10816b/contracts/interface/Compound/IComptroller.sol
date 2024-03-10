// SPDX-License-Identifier: GPL-3.0-or-later
// code borrowed from https://etherscan.io/address/0x75442ac771a7243433e033f3f8eab2631e22938f#code

pragma solidity 0.8.6;

/**
 * @title Compound's Comptroller Contract
 * @author Compound
 */
interface IComptroller {
    /**
     * @notice Official mapping of cTokens -> Market metadata
     * @dev Used e.g. to determine if a market is supported
     */
    function markets(address market) external view returns (bool isListed, uint256 collateralFactorMantissa, bool isComped);

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() external view returns (address[] memory);
}

