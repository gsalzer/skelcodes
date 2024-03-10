// SPDX-License-Identifier: AGPL-3.0-or-later

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
// Example get from https://github.com/ConsenSys/Tokens
pragma solidity ^0.6.0;

abstract contract Token {

    /// total amount of tokens
    uint256 public totalSupply;

    function balanceOf(address _owner) virtual external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) virtual external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) virtual external returns (bool success);

    function approve(address _spender, uint256 _value) virtual external returns (bool success);

    function allowance(address _owner, address _spender) virtual external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

