pragma solidity ^0.5.13;

import "./AddressSet.sol";

contract BurnerRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private burners;

    event BurnerAddition(address indexed addr);
    event BurnerRemoval(address indexed addr);

    modifier ifBurner(address _addr) {
        require(isBurner(_addr),
            "BurnerRole: specified account does not have the Burner role");
        _;
    }

    modifier onlyBurner() {
        require(isBurner(msg.sender),
            "BurnerRole: caller does not have the Burner role");
        _;
    }

    function getBurners()
        public
        view
        returns (address[] memory)
    {
        return burners.elements;
    }

    function isBurner(address _addr)
        public
        view
        returns (bool)
    {
        return burners.has(_addr);
    }

    function numBurners()
        public
        view
        returns (uint)
    {
        return burners.elements.length;
    }

    function _addBurner(address _addr)
        internal
    {
        require(burners.insert(_addr),
            "BurnerRole: duplicate bearer");
        emit BurnerAddition(_addr);
    }

    function _removeBurner(address _addr)
        internal
    {
        require(burners.remove(_addr),
            "BurnerRole: not a bearer");
        emit BurnerRemoval(_addr);
    }
}

