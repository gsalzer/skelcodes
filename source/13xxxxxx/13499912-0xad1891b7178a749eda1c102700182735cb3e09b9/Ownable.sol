//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract Ownable {
    bytes32 internal constant OWNER_SLOT = 0x6f22771533cb498d9c542c0edce990bcb2dc1bd19f34fa7e9a1946cd186410c2;
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor()
    {
        setOwner(msg.sender);
    }

    modifier onlyOwner()
    {
        require(msg.sender == owner());
        _;
    }

    function owner() view public returns(address _owner)
    {
        bytes32 slot = OWNER_SLOT;
        assembly
        {
            _owner := sload(slot)
        }
    }

    function initProxy() external
    {
        require(owner() == address(0x0));
        
        bytes32 slot = IMPLEMENTATION_SLOT;
        address impl;
        assembly {
            impl := sload(slot)
        }

        setOwner(Ownable(impl).owner());
    }

    function ChangeOwner(address newOwner) external onlyOwner
    {
        setOwner(newOwner);
    }

    function setOwner(address newOwner) private
    {
        bytes32 slot = OWNER_SLOT;
        assembly
        {
            sstore(slot, newOwner)
        }
    }
}
