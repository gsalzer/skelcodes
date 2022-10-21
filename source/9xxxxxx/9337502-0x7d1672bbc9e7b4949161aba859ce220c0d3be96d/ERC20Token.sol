pragma solidity ^0.4.13;

import "./TokenRecipientInterface.sol";
import "./ERC20TokenInterface.sol";
import "./Owned.sol";
import "./SafeMath.sol";
import "./Lockable.sol";

contract ERC20Token is ERC20TokenInterface, SafeMath, Owned, Lockable {

    /* Public variables of the token */
    string public standard;
    string public name;
    string public symbol;
    uint8 public decimals;

    bool mintingEnabled;

    /* Private variables of the token */
    uint256 supply = 0;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;

    event Mint(address indexed _to, uint256 _value);
    event Burn(address indexed _from, uint _value);

    /* Returns total supply of issued tokens */
    function totalSupply() constant public returns (uint256) {
        return supply;
    }

    /* Returns balance of address */
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfers tokens from your address to other */
    function transfer(address _to, uint256 _value) lockAffected public returns (bool success) {
        require(_to != 0x0 && _to != address(this));
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);  // Deduct senders balance
        balances[_to] = safeAdd(balanceOf(_to), _value);                // Add recivers blaance
        Transfer(msg.sender, _to, _value);                              // Raise Transfer event
        return true;
    }

    /* Approve other address to spend tokens on your account */
    function approve(address _spender, uint256 _value) lockAffected public returns (bool success) {
        allowances[msg.sender][_spender] = _value;        // Set allowance
        Approval(msg.sender, _spender, _value);           // Raise Approval event
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) lockAffected public returns (bool success) {
        TokenRecipientInterface spender = TokenRecipientInterface(_spender);    // Cast spender to tokenRecipient contract
        approve(_spender, _value);                                              // Set approval to contract for _value
        spender.receiveApproval(msg.sender, _value, this, _extraData);          // Raise method on _spender contract
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) lockAffected public returns (bool success) {
        require(_to != 0x0 && _to != address(this));
        balances[_from] = safeSub(balanceOf(_from), _value);                            // Deduct senders balance
        balances[_to] = safeAdd(balanceOf(_to), _value);                                // Add recipient blaance
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value); // Deduct allowance for this address
        Transfer(_from, _to, _value);                                                   // Raise Transfer event
        return true;
    }

    function allowance(address _owner, address _spender) constant public returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    /* Owner can mint new tokens while minting is enabled */
    function mint(address _to, uint256 _amount) onlyOwner public {
        require(mintingEnabled);                       // Check if minting is enabled
        supply = safeAdd(supply, _amount);              // Add new token count to totalSupply
        balances[_to] = safeAdd(balances[_to], _amount);// Add tokens to recipients wallet
        Mint(_to, _amount);                             // Raise event that anyone can see
        Transfer(0x0, _to, _amount);                    // Raise transfer event
    }

    /* Anyone can destroy tokens on their walllet */
    function burn(uint _amount) public {
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _amount);
        supply = safeSub(supply, _amount);
        Burn(msg.sender, _amount);
        Transfer(msg.sender, 0x0, _amount);
    }

    /* Owner can salvage tokens that were accidentally sent to the smart contract address */
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }
    
    /* Owner can wipe all the data from the contract and disable all the methods */
    function killContract() onlyOwner public {
        selfdestruct(owner);
    }

    /* Owner can disable minting forever and ever */
    function disableMinting() onlyOwner public {
        mintingEnabled = false;
    }
}
