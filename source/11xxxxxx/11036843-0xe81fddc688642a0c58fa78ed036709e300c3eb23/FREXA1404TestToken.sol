pragma solidity ^0.4.4;
import "./Whitelist.sol";

//standard ERC20 implementation
contract ERC20 {

    /// @return total amount of tokens
    function totalSupply() constant returns (uint256 supply) {}

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract StandardToken is ERC20 {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}

//extend ERC20 with ERC1404 standard
contract ERC1404 is ERC20 {
    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string);
}

//begin ERC-1404 Custom Implementation
/**
 * An `ERC20` compatible token that that posits a standardized interface
 * for issuing tokens with transfer restrictions.
 *
 * Implementation Details.
 *
 * An implementation of this token standard SHOULD provide the following:
 *
 * `name` - for use by wallets and exchanges.
 * `symbol` - for use by wallets and exchanges.
 * `decimals` - for use by wallets and exchanges
 * `totalSupply` - for use by wallets and exchanges 
 *
 * The implementation MUST take care to implement desired
 * transfer restriction logic correctly.
 */

/// @title Reference implementation for the ERC-1404 token
/// @notice This implementation has a transfer restriction that prevents token holders from sending to the zero address
/// @dev Ref https://github.com/ethereum/EIPs/pull/SRS
contract ERC1404CustomImpl is ERC1404, StandardToken, Whitelist {
    /// @notice Restriction codes and messages as constant variables
    /// @dev Holding restriction codes and messages as constants is not required by the standard
    string public constant UNKNOWN_MESSAGE = "UNKNOWN";
    uint8 public constant SUCCESS_CODE = 0;
    string public constant SUCCESS_MESSAGE = "SUCCESS";
    uint8 public constant ZERO_ADDRESS_RESTRICTION_CODE = 1;
    string public constant ZERO_ADDRESS_RESTRICTION_MESSAGE = "ILLEGAL_TRANSFER_TO_ZERO_ADDRESS";
    uint8 public constant SEND_NOT_ALLOWED_CODE = 2;
    string public constant SEND_NOT_ALLOWED_MESSAGE = "ILLEGAL_TRANSFER_SENDING_ACCOUNT_NOT_WHITELISTED";
    uint8 public constant RECEIVE_NOT_ALLOWED_CODE = 3;
    string public constant RECEIVE_NOT_ALLOWED_MESSAGE = "ILLEGAL_TRANSFER_RECEIVING_ACCOUNT_NOT_WHITELISTED";


    /// @notice Checks if a transfer is restricted, reverts if it is
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @dev Defining this modifier is not required by the standard, using detectTransferRestriction and appropriately emitting TransferRestricted is however
    modifier notRestricted (address from, address to, uint256 value) {
        uint8 restrictionCode = detectTransferRestriction(from, to, value);
        require(restrictionCode == SUCCESS_CODE, messageForTransferRestriction(restrictionCode));
        _;
    }

    /// @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Code by which to reference message for rejection reasoning
    /// @dev Overwrite with your custom transfer restriction logic
    function detectTransferRestriction (address from, address to, uint256 value)
        public view returns (uint8 restrictionCode)
    {
        restrictionCode = SUCCESS_CODE; // successful transfer
        
        if (to == address(0x0)) {
            restrictionCode = ZERO_ADDRESS_RESTRICTION_CODE; // illegal transfer to zero address
        } else if (!whitelist[from]) {
            restrictionCode = SEND_NOT_ALLOWED_CODE; // sender address not whitelisted
        } else if (!whitelist[to]) {
            restrictionCode = RECEIVE_NOT_ALLOWED_CODE; // receiver address not whitelisted
        }
    }

    /// @notice Returns a human-readable message for a given restriction code
    /// @param restrictionCode Identifier for looking up a message
    /// @return Text showing the restriction's reasoning
    /// @dev Overwrite with your custom message and restrictionCode handling
    function messageForTransferRestriction (uint8 restrictionCode)
        public view returns (string message)
    {
        message = UNKNOWN_MESSAGE;
        if (restrictionCode == SUCCESS_CODE) {
            message = SUCCESS_MESSAGE;
        } else if (restrictionCode == ZERO_ADDRESS_RESTRICTION_CODE) {
            message = ZERO_ADDRESS_RESTRICTION_MESSAGE;
        } else if (restrictionCode == SEND_NOT_ALLOWED_CODE) {
            message = SEND_NOT_ALLOWED_MESSAGE;
        } else if (restrictionCode == RECEIVE_NOT_ALLOWED_CODE) {
            message = RECEIVE_NOT_ALLOWED_MESSAGE;
        }
    }

    /// @notice Subclass implementation of StandardToken's ERC20 transfer method
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Transfer success status
    /// @dev Must compare the return value of detectTransferRestriction to 0
    function transfer (address to, uint256 value)
        public notRestricted(msg.sender, to, value) returns (bool)
    {
        return super.transfer(to, value);
    }
  
    /// @notice Subclass implementation of StandardToken's ERC20 transferFrom method
    /// @param from Sending address
    /// @param to Receiving address
    /// @param value Amount of tokens being transferred
    /// @return Transfer success status
    /// @dev Must compare the return value of detectTransferRestriction to 0
    function transferFrom (address from, address to, uint256 value)
        public notRestricted(from, to, value) returns (bool)
    {
        return super.transferFrom(from, to, value);
    }
}

//name this contract whatever you'd like
contract FREXATestToken3 is ERC1404CustomImpl {

    function () {
        //if ether is sent to this address, send it back.
        throw;
    }

    /* Public variables of the token */

    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It's like comparing 1 wei to 1 ether.
    string public symbol;                 //An identifier: eg SBX
    string public version = 'H1.3.0';       //human 0.1 standard. Just an arbitrary versioning scheme.

//
// CHANGE THESE VALUES FOR YOUR TOKEN
//

//make sure this function name matches the contract name above. So if you're token is called TutorialToken, make sure the //contract name above is also TutorialToken instead of ERC20Token

    function FREXATestToken3(
        ) {
        balances[msg.sender] = 20000;               // Give the creator all initial tokens (100000 for example)
        totalSupply = 20000;                        // Update total supply (100000 for example)
        name = "FREXA ERC-1404 Test3";              // Set the name for display purposes
        decimals = 0;                               // Amount of decimals for display purposes
        symbol = "FRXT3";                           // Set the symbol for display purposes
        addAddressToWhitelist(msg.sender);
    }

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}

