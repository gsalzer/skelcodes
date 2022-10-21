// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20Basic.sol";


/**
 * @title ERC20 interface
 */
abstract contract ERC20 is ERC20Basic {

    function allowance(address _owner, address _spender)  public virtual view returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool);

    function approve(address _spender, uint256 _value) public virtual returns (bool);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

