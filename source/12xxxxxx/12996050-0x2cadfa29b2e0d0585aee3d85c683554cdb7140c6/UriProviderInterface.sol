pragma solidity ^0.5.0;

/// @title BlockchainCuties: Collectible and breedable cuties on the Ethereum blockchain.
/// @author https://BlockChainArchitect.io
interface UriProviderInterface {
    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory infoUrl);
}

