pragma solidity ^0.6.0;



interface IConsensusUSD {

    /// @param _amount The amount of consensus dollar tokens to mint
    /// @param _assetUsed The token address of asset used to mint consensus dollar tokens
    /// @return success indicating if minting was successful
    function mint(uint256 _amount, address _assetUsed) external returns (bool success);

    /// @param _amount The amount of asset to retrieve from contract, equals the amount of tokens burnt
    /// @param _assetRetrieved The token address of asset which is going to be retrieved
    /// @return success indicating if retrieval was successful
    function retrieve(uint256 _amount,  address _assetRetrieved) external returns (bool success);

    /// @param _asset Token address of asset
    /// @return success indicating if token address is valid asset or not
    function isValidAsset(address _asset) external view returns (bool success);

    /// @param _owner Address of which to consult locked asset balance
    /// @param _asset Token address of asset
    /// @return asset uint256 amount of specified asset locked by _owner
    function assetLockedOf(address _owner, address _asset) external view returns (uint256 asset);

    event Mint(address indexed _minter, uint256 _value);
    event Burn(address indexed _burner, uint256 _value);

}

