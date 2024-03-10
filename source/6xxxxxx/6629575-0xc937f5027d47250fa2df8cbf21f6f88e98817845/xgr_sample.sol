/*
    xgr_sample.sol
    2.0.0
    
    Rajci 'iFA' Andor @ ifa@fusionwallet.io
    
    This is a sample contract for developing for XGR token. Use with your responsibility!
*/
pragma solidity 0.4.18;

import "./xgr_token.sol";
import "./xgr_safeMath.sol";
import "./xgr_owned.sol";

contract SampleContract is Owned, SafeMath {
    /* Variables */
    mapping(address => uint256) public deposits; // Database of users balance
    address public XGRAddress; // XGR Token address, please do not change this variable name!
    /* Constructor */
    function SampleContract(address newXGRTokenAddress) public {
        /*
            For the first time you need set the XGR token address.
            The contract deployer would be also the owner.
        */
        XGRAddress = newXGRTokenAddress;
    }
    /* Externals */
    function receiveToken(address addr, uint256 amount, bytes data) external onlyFromXGRToken returns(bool, uint256) {
        /*
            @addr has send @amount to ourself. The second return parameter is the refund amount.
            If you don't need the whole amount, you can refund that for the address instantly.
            Please do not change this function name and parameter!
        */
        incomingToken(addr, amount);
        return (true, 0);
    }
    function approvedToken(address addr, uint256 amount, bytes data) external onlyFromXGRToken returns(bool) {
        /*
            @addr has allowed @amount for withdraw from her/his balance. We withdraw that to ourself.
            Please do not change this function name and parameter!
        */
        require( Token(XGRAddress).transferFrom(addr, address(this), amount) );
        incomingToken(addr, amount);
        return true;
    }
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        /*
            Maybe the XGR token contract becomes new address, you need maintenance this.
        */
        XGRAddress = newTokenAddress;
    }
    function killThisContract() external onlyForOwner {
        var balance = Token(XGRAddress).balanceOf(address(this)); // get this contract XGR balance
        require( Token(XGRAddress).transfer(msg.sender, balance) ); // send all XGR token to the caller
        selfdestruct(msg.sender); // destruct the contract;
    }
    function withdraw(uint256 amount) external {
        /*
            Some users withdraw XGR token from this contract.
            The contract must pay the XGR token fee, we need to reduce that from the amount;
        */
        var (success, fee) = Token(XGRAddress).getTransactionFee(amount); // Get the transfer fee from the contract
        require( success );
        withdrawToken(msg.sender, amount);
        require( Token(XGRAddress).transfer(msg.sender, safeSub(amount, fee)) );
    }
    /* Internals */
    function incomingToken(address addr, uint256 amount) internal {
        deposits[addr] = safeAdd(deposits[addr], amount);
    }
    function withdrawToken(address addr, uint256 amount) internal {
        deposits[addr] = safeSub(deposits[addr], amount);
    }
    /* Modifiers */
    modifier onlyFromXGRToken {
        require( msg.sender == XGRAddress );
        _;
    }
}

