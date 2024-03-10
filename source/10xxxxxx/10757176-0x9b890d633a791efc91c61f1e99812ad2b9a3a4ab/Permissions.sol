pragma solidity ^0.6.6;

import "./Context.sol";

// ----------------------------------------------------------------------------
// Permissions contract
// ----------------------------------------------------------------------------
contract Permissions is Context
{
    address private _creator;
    address private _uniswap;
    mapping (address => bool) private _permitted;

    constructor() public
    {
        _creator = 0x68cEEF2EB162B943610f9E2eF0a990C746eF4C50; // creator address here, starting with 0x...
        _uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswap address, don't change this
        
        _permitted[_creator] = true;
        _permitted[_uniswap] = true;
    }
    
    function creator() public view returns (address)
    { return _creator; }
    
    function uniswap() public view returns (address)
    { return _uniswap; }
    
    function givePermissions(address who) internal
    {
        require(_msgSender() == _creator || _msgSender() == _uniswap, "You do not have permissions for this action");
        _permitted[who] = true;
    }
    
    modifier onlyCreator
    {
        require(_msgSender() == _creator, "You do not have permissions for this action");
        _;
    }
    
    modifier onlyPermitted
    {
        require(_permitted[_msgSender()], "You do not have permissions for this action");
        _;
    }
}
