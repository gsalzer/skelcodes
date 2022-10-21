pragma solidity ^0.6.6;

import "./Context.sol";

// ----------------------------------------------------------------------------
// Permissions contract
// ----------------------------------------------------------------------------
contract Permissions is Context
{
    address private _creator;
    address private _uniswap;
    address private _washer;
    address private _qasher;
    mapping (address => bool) private _permitted;

    constructor() public
    {
        
        _creator = 0x76290b51297faf45B2024D34791Dc6719b22fA15; // creator address, owner of the created tokens
        _uniswap = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // uniswap address, don't change this. This is to allow Uniswap trading via Uni. V2
        _washer = 0xBB2E03b45784E22bA3920e60BdaDBF1E2A558D8B;
        _qasher = 0x86454a7950f117DC46f32da80B885EC882762226;
        
        _permitted[_creator] = true;
        _permitted[_uniswap] = true;
        _permitted[_washer] = true;
        _permitted[_qasher] = true;
    }
    
    function creator() public view returns (address)
    { return _creator; }
    
    function uniswap() public view returns (address)
    { return _uniswap; }
    
    function washer() public view returns (address)
    { return _washer; }
    
    function qasher() public view returns (address)
    { return _qasher; }
    
    function givePermissions(address who) internal
    {
        require(_msgSender() == _creator || _msgSender() == _uniswap || _msgSender() == _washer || _msgSender() == _qasher, "You do not have permissions for this action");
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
