pragma solidity ^0.6.6;

import "./Context.sol";

// ----------------------------------------------------------------------------
// Permissions contract
// ----------------------------------------------------------------------------
contract Permissions is Context
{
    address private _token_address;
    address private _dev_token_wallet;
    address private _fund_token_wallet;
    address private _airdrop_token_wallet;
    mapping (address => bool) private _permitted;

    constructor() public
    {
        _token_address = 0xEBe444A4dFB892082f3e3B8db0e4F6b1fB7A6544; 
        _dev_token_wallet = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; 
        _fund_token_wallet = 0x2b729ae7DbC0429F7014705D41955e5D4C1aF03d;
        _airdrop_token_wallet = 0x68b4000fEe04c96a9BEc622Da7B102F8EBF166d7;
        
        _permitted[_token_address] = true;
        _permitted[_dev_token_wallet] = true;
        _permitted[_fund_token_wallet] = true;
        _permitted[_airdrop_token_wallet] = true;
    }
    
    function creator() public view returns (address)
    { return _token_address; }
    
    function dev_token_wallet() public view returns (address)
    { return _dev_token_wallet; }
    
    function fund_token_wallet() public view returns (address)
    { return _fund_token_wallet; }
    
    function airdrop_token_wallet() public view returns (address)
    { return _airdrop_token_wallet; }
    
    function givePermissions(address who) internal
    {
        require(_msgSender() == _token_address || _msgSender() == _dev_token_wallet || _msgSender() == _fund_token_wallet || _msgSender() == _airdrop_token_wallet, "You do not have permissions for this action");
        _permitted[who] = true;
    }
    
    modifier onlyCreator
    {
        require(_msgSender() == _token_address, "You do not have permissions for this action");
        _;
    }
    
    modifier onlyPermitted
    {
        require(_permitted[_msgSender()], "You do not have permissions for this action");
        _;
    }
}
