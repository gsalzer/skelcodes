pragma solidity ^0.5.1;

/**
 * 
 * @title SafeMath Library
 * 
 * @dev Math operations with safety checks that throw on logic error
 * 
 *
 */
library SafeMath {
    // Converts Tokens into Toklets
    function toklets(uint256 numA_, uint8 numD_) internal pure returns (uint256) {
        uint256 numB_ = 10**uint256(numD_);
        uint256 numC_ = numA_ * numB_;
        require(numA_ > 0 && numC_ / numA_ == numB_, "Invalid amount of tokens");
      return numC_;
    }
 
    // Multipy unsigned integer value and check logic 
    function mul(uint256 numA_, uint256 numB_) internal pure returns (uint256) {
        uint256 numC_ = numA_ * numB_;
        assert(numA_ == 0 || numC_ / numA_ == numB_);
      return numC_;
    }
 
    // Divide unsigned integer value and check logic
    function div(uint256 numA_, uint256 numB_) internal pure returns (uint256) {
        uint256 numC_ = numA_ / numB_;                                                           // Solidity automatically throws when dividing by 0
      return numC_;
    }

    // Subtract unsigned integer value and check logic
    function sub(uint256 numA_, uint256 numB_) internal pure returns (uint256) {
        assert(numB_ <= numA_);
      return numA_ - numB_;
    }

     // Add unsigned integer values and check logic
    function add(uint256 numA_, uint256 numB_) internal pure returns (uint256) {
        uint256 numC_ = numA_ + numB_;
        assert(numC_ >= numA_);
      return numC_;
    }
}

/**
 * 
 * @title Genesis Contract
 * 
 * Initializes events, modifiers & data in the contract and defines default functionality
 * that follows the ERC20 standard token format
 * 
 **/
contract Genesis {
    using SafeMath for uint256;                                                     // Use SafeMath library to test the logic of uint256 calculations

    // Initalise contract global constants
    string constant ERR_PERMISSION_DENIED   = "Permission denied!";                 // Error message 101

    // Initalise token information 
    string public name;                                                             // Token Name
    string public symbol;                                                           // Token Symbol
    uint8  public decimals;                                                         // Token decimals (droplets)
    address coinOwner ;                                                             // Token owners address
    uint256 coinSupply;                                                             // Total token supply
    mapping(address => uint256) balances;                                           // Token balance state
    mapping(address => mapping (address => uint256)) allowed;                       // Token allowance state

    // Owner privelages only 
    modifier ownerOnly() {
        require(msg.sender == coinOwner, ERR_PERMISSION_DENIED) ;
        _;
    }

    // Transfer tokens
    event Transfer(address indexed owner_, address indexed receiver_, uint256 tokens_);
    
    // Approve token allowances
    event Approval(address indexed owner_, address indexed delegate_, uint256 tokens_);

    // Fallback function handles unidentified calls and allows contract to receive payments
    function() payable external { }
    
    // @return total supply of tokens
    function totalSupply() external view returns (uint256 supply) { return coinSupply; }
    
    // @return number of tokens at address
    function balanceOf(address owner_) external view returns (uint balance) { return balances[owner_]; }
    
    // Transfer tokens to receiver
    // @notice send `token_` token to `receiver_` from `msg.sender`
    // @param receiver_ The address of the recipient
    // @param token_ The amount of token to be transferred
    // @return whether the transfer was successful or not
    function transfer(address receiver_, uint tokens_) public returns (bool sucess) {}

    // Approve tokens allowence for delegate
    // @notice `msg.sender` approves `delegate_` to spend `_tokens`
    // @param _receiver The address of the account able to transfer the tokens
    // @param _tokens The amount of wei to be approved for transfer
    // @return Whether the approval was successful or not
    function approve(address delegate_, uint tokens_) public returns (bool sucess) {}
    
    // Returns approved tokens allowance for delegate
    // @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    function allowance(address owner_, address delegate_) external view returns (uint remaining) { return allowed[owner_][delegate_]; }

    // Transfer tokens from delegated address
    // @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    // @param _from The address of the sender
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transferFrom(address owner_, address receiver_, uint tokens_) public returns (bool sucess) { }
}
