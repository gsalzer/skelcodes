pragma solidity ^0.5.13;

import "./AddressSet.sol";

contract MinterRole {
    using AddressSet for AddressSet.addrset;

    AddressSet.addrset private minters;

    event MinterAddition(address indexed addr);
    event MinterRemoval(address indexed addr);

    modifier ifMinter(address _addr) {
        require(isMinter(_addr),
            "MinterRole: specified account does not have the Minter role");
        _;
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender),
            "MinterRole: caller does not have the Minter role");
        _;
    }

    function getMinters()
        public
        view
        returns (address[] memory)
    {
        return minters.elements;
    }

    function isMinter(address _addr)
        public
        view
        returns (bool)
    {
        return minters.has(_addr);
    }

    function numMinters()
        public
        view
        returns (uint)
    {
        return minters.elements.length;
    }

    function _addMinter(address _addr)
        internal
    {
        require(minters.insert(_addr),
            "MinterRole: duplicate bearer");
        emit MinterAddition(_addr);
    }

    function _removeMinter(address _addr)
        internal
    {
        require(minters.remove(_addr),
            "MinterRole: not a bearer");
        emit MinterRemoval(_addr);
    }
}

