// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IYRegistry {
    /**
     * @notice Checks if the given token has a registered `Vault`.
     * @param _token The token address.
     * @return bool True if the token has a registered `Vault`.
     */
    function isRegistered(address _token) external view returns (bool);

    /**
     * @notice Gives the lates `Vault` implementation of the given token.
     * @param _token The token address.
     * @return address The latest `Vault` address.
     */
    function latestVault(address _token) external view returns (address);

    /**
     * @notice Gives the count of implemented `Vaults` of the token.
     * @param _token The token address.
     * @return count The count of implemented `Vaults`. 
     */
    function numVaults(address _token) external view returns (uint256);

    /**
     * @notice Gives the address of `Vault`. It takes `token` and `vaultId` as parameters.
     * @param _token The token address.
     * @param _vaultId The vault index.
     */
    function vaults(address _token, uint256 _vaultId) external view returns (address);

    /**
     * @notice Returns total number of tokens that has a `Vault`.
     * @return count The number of tokens.
     */
    function numTokens() external view returns (uint256);

    /**
     * @notice Returns the token for a given token index.
     * @param _tokenIndex The token index.
     * @return address The token address.
     */
    function tokens(uint256 _tokenIndex) external view returns (address);
}

