// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IYVault {
    /**
     * @notice Returns underlying token.
     * @return address Underlying token address.
     */
    function token() external view returns (address);

    /**
     * @notice Returns user balance in vault.
     * @return balance User balance 
     */
    function balanceOf(address user) external view returns (uint256);

    /**
     * @notice Returns the price for a single `Vault` share.
     * @return share The value of a single share
     */
    function pricePerShare() external view returns (uint256);

    /**
     * @notice Deposits `_amount` `token`, issuing shares to `recipient`. If the
     * Vault is in Emergency Shutdown, deposits will not be accepted and this
     * call will fail.
     */
    function deposit(uint256 amount) external;

    /**
     * @notice Returns the name of the `Vault`.
     * @return name `Vault` name.
     */
    function name() external view returns (string memory);

    /**
     * @notice Returns the symbol of the `Vault`.
     * @return symbol `Vault` symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @notice Returns the decimals value of the `Vault`.
     * @return decimals `Vault` decimals.
     */
    function decimals() external view returns (uint256);
}

