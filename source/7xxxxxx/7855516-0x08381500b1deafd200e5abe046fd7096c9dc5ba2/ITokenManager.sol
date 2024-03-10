pragma solidity >=0.5.3 < 0.6.0;

/// @author Ryan @ Protea 
/// @title ERC20 compliant interface for Token Manager  
interface ITokenManager {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint value);

    /// @dev                Transfer ownership token from msg.sender to a specified address
    /// @param _to          :address The address to transfer to.
    /// @param _value       :uint256 The amount to be transferred.
    function transfer(address _to, uint256 _value) external returns (bool);

    /// @dev                Transfer tokens from one address to another
    /// @param _from        :address The address which you want to send tokens from
    /// @param _to          :address The address which you want to transfer to
    /// @param _value       :uint256 the amount of tokens to be transferred
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @dev                This function returns the amount of tokens one can receive for a specified amount of collateral token
    ///                     Including Protea & Community contributions
    /// @param  _colateralTokenOffered  :uint256 Amount of reserve token offered for purchase
    function colateralToTokenBuying(uint256 _colateralTokenOffered) external view returns(uint256);

    /// @dev                 This function returns the amount of tokens needed to be burnt to withdraw a specified amount of reserve token
    ///                                 Including Protea & Community contributions
    /// @param  _collateralTokenNeeded  :uint256 Amount of dai to be withdraw
    function colateralToTokenSelling(uint256 _collateralTokenNeeded) external view returns(uint256);

    /// @dev               Returns the required collateral amount for a volume of bonding curve tokens
    /// @return            Required collateral corrected for decimals
    function priceToMint(uint256 _numTokens) external view returns(uint256);

    /// @dev                Returns the required collateral amount for a volume of bonding curve tokens
    /// @return             Potential return collateral corrected for decimals
    function rewardForBurn(uint256 _numTokens) external view returns(uint256);

    /// @dev                Selling tokens back to the bonding curve for collateral
    /// @param _numTokens   The number of tokens that you want to burn
    function burn(uint256 _numTokens) external returns(bool);

    /// @dev                Mint new tokens with ether
    /// @param _to          :address Address to mint tokens to
    /// @param _numTokens   :uint256 The number of tokens you want to mint
    /// @dev                We have modified the minting function to divert a portion of the purchase tokens
    function mint(address _to, uint256 _numTokens) external returns(bool);

    /// @dev                Gets the value of the current allowance specifed for that account
    /// @param _owner       :address The account sending the funds.
    /// @param _spender     :address The account that will receive the funds.
    /// @return             An uint256 representing the amount owned by the passed address.
    function allowance(address _owner, address _spender) external view returns (uint256);
    
    /// @dev                Gets the balance of the specified address.
    /// @param _spender     :address The account that will receive the funds.
    /// @param _value       :uint256 The value of funds accessed.
    /// @return             :boolean Indicating the action was successful.
    function approve(address _spender, uint256 _value) external returns (bool success);
    
    /// @dev                Gets the balance of the specified address.
    /// @param _owner       :address The address to query the the balance of.
    /// @return             An uint256 representing the amount owned by the passed address.
    function balanceOf(address _owner) external view returns (uint256);

    /// @dev                Total number of tokens in existence
    /// @return             A uint256 representing the total supply of tokens in this market
    function totalSupply() external view returns (uint256);

}
