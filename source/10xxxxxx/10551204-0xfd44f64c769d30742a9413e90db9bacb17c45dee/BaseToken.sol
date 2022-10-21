// SPDX-License-Identifier: AGPL-3.0-or-later

// This is modified StandardToken contract from https://github.com/ConsenSys/Tokens
// Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.6.0;

import "./Token.sol";

contract BaseToken is Token {

    function transfer(address _to, uint256 _value) override virtual external returns (bool success) {
        require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) override virtual external returns (bool success) {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) view override virtual external returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) override virtual external returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) override virtual external view returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
}

