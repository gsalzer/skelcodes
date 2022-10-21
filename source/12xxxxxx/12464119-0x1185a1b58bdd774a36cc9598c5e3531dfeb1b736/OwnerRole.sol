pragma solidity ^0.5.13;

import "./AddressSet.sol";

contract OwnerRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private owners;

    event OwnerAddition(address indexed addr);
    event OwnerRemoval(address indexed addr);

    modifier ifOwner(address _addr) {
        require(isOwner(_addr),
            "OwnerRole: specified account does not have the Owner role");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender),
            "OwnerRole: caller does not have the Owner role");
        _;
    }

    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners.elements;
    }

    function isOwner(address _addr)
        public
        view
        returns (bool)
    {
        return owners.has(_addr);
    }

    function numOwners()
        public
        view
        returns (uint)
    {
        return owners.elements.length;
    }

    function _addOwner(address _addr)
        internal
    {
        require(owners.insert(_addr),
            "OwnerRole: duplicate bearer");
        emit OwnerAddition(_addr);
    }

    function _removeOwner(address _addr)
        internal
    {
        require(owners.remove(_addr),
            "OwnerRole: not a bearer");
        emit OwnerRemoval(_addr);
    }
}

