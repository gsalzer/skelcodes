// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

abstract contract ProjectToken_interface {
    function name() public view virtual returns (string memory);
    function symbol() public view virtual returns (string memory);
    function decimals() public view virtual returns (uint8);

    function owner() public view virtual returns (address);
    function balanceOf(address who) public view virtual returns (uint256);
    
    function transfer(address _to, uint256 _value) public virtual returns (bool);
    function allowance(address _owner, address _spender) public virtual returns (uint);
    function transferFrom(address _from, address _to, uint _value) public virtual returns (bool);
    
    // Tether format
    // function transfer(address _to, uint256 _value) public virtual;
    // function transferFrom(address _from, address _to, uint _value) public virtual;
}

