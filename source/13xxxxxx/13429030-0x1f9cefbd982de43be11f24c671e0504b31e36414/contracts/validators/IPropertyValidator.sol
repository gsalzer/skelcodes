// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

interface IPropertyValidator {
    /// @dev Checks that the given asset data satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenId The ERC721 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function checkBrokerAsset(uint256 tokenId, bytes calldata propertyData)
        external
        view;
}

