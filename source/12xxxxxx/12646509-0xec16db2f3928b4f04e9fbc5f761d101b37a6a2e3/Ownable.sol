// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

/// @title Ownable 
/// @custom:version 1.0.1
/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 * Provides onlyOwnerOrApi modifier, which prevents function from running if it is called by other than above OR from one API code.
 * Provides onlyOwnerOrApiOrContract modifier, which prevents function from running if it is called by other than above OR one smart contract code.
 * Provides onlySuperOwnerOrOwnerOrApiOrContract modifier, which prevents function from running if it is called by other than all whitelisted addresses.
 */
abstract contract Ownable {
    address public superOwnerAddr;
    address public ownerAddr;
    mapping(address => bool) public ApiAddr; // list of allowed apis
    mapping(address => bool) public ContractAddr; // list of allowed contracts

    constructor(address superOwner, address owner, address api) {
        superOwnerAddr = superOwner;
        ownerAddr = owner;
        ApiAddr[api] = true;
    }

    modifier onlySuperOwner() {
        require(msg.sender == superOwnerAddr, "Access denied for this address [0].");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddr, "Access denied for this address [1].");
        _;
    }

    modifier onlyOwnerOrApi() {
        require(msg.sender == ownerAddr || ApiAddr[msg.sender] == true, "Access denied for this address [2].");
        _;
    }

    modifier onlyOwnerOrApiOrContract() {
        require(msg.sender == ownerAddr || ApiAddr[msg.sender] == true || ContractAddr[msg.sender] == true, "Access denied for this address [3].");
        _;
    }

    modifier onlySuperOwnerOrOwnerOrApiOrContract() {
        require(msg.sender == superOwnerAddr || msg.sender == ownerAddr || ApiAddr[msg.sender] == true || ContractAddr[msg.sender] == true, "Access denied for this address [3].");
        _;
    }

    function setOwnerAddr(address _address) public onlySuperOwner {
        ownerAddr = _address;
    }
    
    function addApiAddr(address _address) public onlyOwner {
        ApiAddr[_address] = true;
    }

    function removeApiAddr(address _address) public onlyOwner {
        ApiAddr[_address] = false;
    }

    function addContractAddr(address _address) public onlyOwner {
        ContractAddr[_address] = true;
    }

    function removeContractAddr(address _address) public onlyOwner {
        ContractAddr[_address] = false;
    }
}
