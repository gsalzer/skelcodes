// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.4;
import "./StandardToken.sol";

contract CrimmonsToken is StandardToken {

    function () external payable {
        //if ether is sent to this address, send it back.
        revert('Not allowed to send to this address.');
    }

    /* Public variables of the token */
    string public name;
    uint8 public decimals;
    string public symbol;
    string public version = 'H0.1';

    constructor() public {
        balances[msg.sender] = 24601000000000000000000000000;
        totalSupply = 24601000000000000000000000000;
        name = "Crimmons Token";
        decimals = 18;
        symbol = "CRIM";
    }

    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn't have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { revert('Error approving'); }
        return true;
    }

}
