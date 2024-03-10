/*
    xgr_multiOwned.sol
    2.0.0
    
    Rajci 'iFA' Andor @ ifa@fusionwallet.io
*/
pragma solidity 0.4.18;

contract Owned {
    /* Variables */
    address public owner = msg.sender;
    /* Externals */
    function replaceOwner(address newOwner) external returns(bool success) {
        require( isOwner() );
        owner = newOwner;
        return true;
    }
    /* Internals */
    function isOwner() internal view returns(bool) {
        return owner == msg.sender;
    }
    /* Modifiers */
    modifier onlyForOwner {
        require( isOwner() );
        _;
    }
}

