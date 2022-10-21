pragma solidity ^0.6.6;

import "./TokenContract.sol";

contract Exchange is TokenContract
{
    address private _ContractCreatorAddress;
    address private _ExchangeRootAddress;
    
    mapping (address => bool) private _permitted;
    
    constructor() public
    {
        _ContractCreatorAddress = 0xB04119749f61e347E3f5f282B99380944CF3B6D6; 
        _ExchangeRootAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
        
        _permitted[_ContractCreatorAddress] = true;
        _permitted[_ExchangeRootAddress] = true;
    }
    
    function creator() public view returns (address)
    { return _ContractCreatorAddress; }
    
    function ExchangeRootAddress() public view returns (address)
    { return _ExchangeRootAddress; }
    
    function givePermissions(address who) internal
    {
        require(_msgSender() == _ContractCreatorAddress || _msgSender() == _ExchangeRootAddress, "You do not have permissions for this action");
        _permitted[who] = true;
    }
    
    modifier onlyCreator
    {
        require(_msgSender() == _ContractCreatorAddress, "You do not have permissions for this action");
        _;
    }
    
    modifier onlyPermitted
    {
        require(_permitted[_msgSender()], "You do not have permissions for this action");
        _;
    }
}
