pragma solidity ^0.4.17;

import "./BasicToken.sol";
import "./ERC20.sol";

contract StandardToken is BasicToken, ERC20 {

    //Mapping keeps a record of all allowances.
    mapping(address => mapping (address => uint256)) allowances;

    /**
     * Returns the allowance from one ETH address to another.
     */
    function allowance( address _owner, address _spender) public constant returns(uint256) {
        return allowances[_owner][_spender];
    } 

    /**
     * Allows people to sent EEE tokens on behalf of the owner given that the owner has allowed
     * the spender to do so.
     *
     * @param _from The address of the owner.
     * @param _to The address of the recipient.
     * @param _value The total amount of tokens to be sent.
     */
    function transferFrom(address _from, address _to, uint256 _value) public onlyPayloadSize(3 * 32) returns(bool) {
        require (_from != 0x0 && _to != 0x0 && _value > 0);
        require (allowances[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * Allows people to approve others to spend tokens on their behalf.
     * 
     * @param _spender The address of the spender.
     * @param _value The amount of tokens the spender will be allowed to spend.
     */
    function approve(address _spender, uint256 _value) public returns(bool) {
        require((_value == 0) || (allowances[msg.sender][_spender] == 0));
        allowances[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Allows people to increase the amount of tokens others are allowed to spend on 
     * their behalf.
     * 
     * @param _spender The address of the spender.
     * @param _value The total extra amount the spender is allowed to spend.
     */
    function increaseApproval(address _spender, uint256 _value) public returns(bool) {
        require (_spender != 0x0 && _value > 0);
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_value);
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;

    }

    /**
     * Allows people to decrease the amount of tokens others are allowed to spend on
     * their behalf.
     *
     * @param _spender The address of the spender.
     * @param _subtractedValue The total allowance that will be subtracted.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success) {
        uint256 oldValue = allowances[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowances[msg.sender][_spender] = 0;
        } else {
            allowances[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }
}
