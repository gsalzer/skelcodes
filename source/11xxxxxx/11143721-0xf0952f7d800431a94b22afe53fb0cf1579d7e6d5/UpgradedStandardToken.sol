// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

import "./ERC20WithFee.sol";

abstract contract UpgradedStandardToken is ERC20WithFee {
    // those methods are called by the legacy contract
    // and they must ensure msg.sender to be the contract address
    uint public _totalSupply;
    function transferByLegacy(address from, address to, uint value) public virtual returns (bool);
    function transferFromByLegacy(address sender, address from, address spender, uint value) public virtual returns (bool);
    function approveByLegacy(address from, address spender, uint value) public virtual returns (bool);
    function increaseApprovalByLegacy(address from, address spender, uint addedValue) public virtual returns (bool);
    function decreaseApprovalByLegacy(address from, address spender, uint subtractedValue) public virtual returns (bool);
}
