// © Copyright 2020. Patent pending. All rights reserved. Perpetual Altruism Ltd.
pragma solidity 0.6.6;

import "./VCProxy.sol";
import "./AuctionHouseV1.sol";

/// @author Guillaume Gonnaud 2020
/// @title ERC20 Generic placeholder smart contract for testing and ABI
/// @notice Contain all the storage of the auction house declared in a way that generate getters for Logic Code use, but no code that changes memory
contract ERC20Generic {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    string public name; // Returns the name of the token - e.g. "MyToken".
    string public symbol; // Returns the symbol of the token. E.g. “HIX”.
    uint8 public decimals; // Returns the number of decimals the token uses - e.g. 8, means to divide the token amount by 100000000 to get its user representation.
    uint256 public totalSupply; //Returns the total token supply.
    mapping(address => uint256) public balanceOf; //Returns the account balance of another account with address _owner.
    mapping(address => mapping(address => uint256)) public individualAllowance; // Mapping of allowance per owner/spender

    /// @notice Transfer a _value amount of ERC token from msg.sender to _to
     /// Throw if msg.sender doesn't have enough tokens
    /// @param _to The address of the recipient
    /// @param _value The amount of token to send
    /// @return success true if success, throw if failed
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value, "msg.sender balance is too low");
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @notice Transfer a _value amount of ERC token from _drom to _to. 
    /// Only work if msg.sender == from or if msg.sender allowance < value
    /// Throw if _from doesn't have enough tokens
    /// @param _from The address of the account being removed tokens
    /// @param _to The address of the account being given tokens
    /// @param _value The amount of token to send
    /// @return success true if success, throw if failed
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balanceOf[_from] >= _value, "_from balance is too low");
        require(individualAllowance[_from][msg.sender] >= _value || msg.sender == _from, "msg.sender allowance with _from is too low");
        individualAllowance[_from][msg.sender] = individualAllowance[_from][msg.sender] - _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @notice Approve an amount of token _spender can spend on behalf of msg.sender
    /// @param _spender The address of the account being approved for tokens
    /// @param _value The amount of token to be spent in total
    /// @return success true if success
    function approve(address _spender, uint256 _value) public returns (bool success){
        individualAllowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @notice get the approved amount of token _spender can spend on behalf of _owner
    /// @param _owner The address of the account being approved for tokens
    /// @param _spender The amount of token to be spent in total
    /// @return remaining the allowance of _spender on behalf of _owner
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return individualAllowance[_owner][_spender];
    }

    /// @notice Mint _value tokens for msg.sender
    /// Function not present in ERC20 spec : allow for the minting of a token for test purposes
    /// @param _value Amount of tokens to mint
    function mint( uint256 _value) public {
        balanceOf[msg.sender] = balanceOf[msg.sender] + _value;
    }

}
