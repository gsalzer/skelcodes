// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @title IMarketplaceSettings Settings governing a marketplace.
 */
interface IMarketplaceSettings {
    /////////////////////////////////////////////////////////////////////////
    // Marketplace Min and Max Values
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMaxValue() external view returns (uint256);

    /**
     * @dev Get the max value to be used with the marketplace.
     * @return uint256 wei value.
     */
    function getMarketplaceMinValue() external view returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Marketplace Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the marketplace fee percentage.
     * @return uint8 wei fee.
     */
    function getMarketplaceFeePercentage() external view returns (uint8);

    /**
     * @dev Utility function for calculating the marketplace fee for given amount of wei.
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculateMarketplaceFee(uint256 _amount)
    external
    view
    returns (uint256);

    /////////////////////////////////////////////////////////////////////////
    // Primary Sale Fee
    /////////////////////////////////////////////////////////////////////////
    /**
     * @dev Get the primary sale fee percentage for a specific ERC1155 contract.
     * @return uint8 wei primary sale fee.
     */
    function getERC1155ContractPrimarySaleFeePercentage()
    external
    view
    returns (uint8);

    /**
     * @dev Utility function for calculating the primary sale fee for given amount of wei
     * @param _amount uint256 wei amount.
     * @return uint256 wei fee.
     */
    function calculatePrimarySaleFee(uint256 _amount)
    external
    view
    returns (uint256);

    /**
     * @dev Check whether the ERC1155 token has sold at least once.
     * @param _tokenId uint256 token ID.
     * @return bool of whether the token has sold.
     */
    function hasTokenSold(uint256 _tokenId)
    external
    view
    returns (bool);

    /**
     * @dev Mark a token as sold.

     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.

     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
    function markERC1155Token(
        uint256 _tokenId,
        bool _hasSold
    ) external;
}

