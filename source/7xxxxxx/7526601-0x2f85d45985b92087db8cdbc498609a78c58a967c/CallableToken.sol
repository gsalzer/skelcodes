pragma solidity ^0.4.23;

import "./StandardToken.sol";
import "./Recipient.sol";


/**
 * @title CallableToken
 * @dev A extension of the StandardToken with methods that allows the execution of calls inside approvals.
 **/
contract CallableToken is StandardToken {

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value The max amount they can spend
     * @param _extraData Extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        if (super.approve(_spender, _value)) {
            Recipient spender = Recipient(_spender);
            spender.receiveApproval(msg.sender, _value, address(this), _extraData);
            return true;
        }
        return false;
    }
}

