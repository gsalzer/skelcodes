pragma solidity ^0.4.25;

/*
 * Ownable
 *
 * Base contract with an owner.
 * Provides onlyOwner modifier, which prevents function from running if it is called by anyone other than the owner.
 * Provides onlyOwnerOrApi modifier, which prevents function from running if it is called by other than above OR from one API code.
 * Provides onlyOwnerOrApiOrContract modifier, which prevents function from running if it is called by other than above OR one smart contract code.
 */
contract Ownable {
    address public superOwnerAddr;
    address public ownerAddr;
    mapping(address => bool) public ApiAddr; // list of allowed apis
    mapping(address => bool) public ContractAddr; // list of allowed contracts

    constructor() public {
        superOwnerAddr = 0xb4e3734A221ebA3137E0F4eA6f49d0c366d03dDa;
        ownerAddr = msg.sender;
        ApiAddr[0x82F5500c79065a768f1D86Cd8bf74b4c34681afE] = true;
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

}
