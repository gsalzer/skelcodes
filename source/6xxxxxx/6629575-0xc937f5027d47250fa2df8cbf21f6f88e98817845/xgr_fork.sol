/*
    xgr_fork.sol
    2.0.0
    
    Rajci 'iFA' Andor @ ifa@fusionwallet.io
*/
pragma solidity 0.4.18;

import "./xgr_token.sol";
import "./xgr_owned.sol";

contract Fork is Owned {
    /* Variables */
    address public uploader;
    address public tokenAddress;
    /* Constructor */
    function Fork(address _uploader) public {
        uploader = _uploader;
    }
    /* Externals */
    function changeTokenAddress(address newTokenAddress) external onlyForOwner {
        tokenAddress = newTokenAddress;
    }
    function upload(address[] addr, uint256[] amount) external onlyForUploader {
        require( addr.length == amount.length );
        for ( uint256 a=0 ; a<addr.length ; a++ ) {
            require( Token(tokenAddress).mint(addr[a], amount[a]) );
        }
    }
    /* Modifiers */
    modifier onlyForUploader {
        require( msg.sender == uploader );
        _;
    }
}

