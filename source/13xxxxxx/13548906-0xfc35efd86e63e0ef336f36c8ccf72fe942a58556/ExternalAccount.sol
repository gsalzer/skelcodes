// SPDX-License-Identifier: MIT

/*
*
* ExternalAccount Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* To be used to allow a single external address (likely another another contract) to interact with particular functions
*
*/

pragma solidity 0.8.9;

import "./Ownable.sol";

contract ExternalAccount is Ownable {

    address public externalAccount;

    function setExternalAccount(address _addr) public onlyOwner {
        externalAccount = _addr;
    }

    modifier onlyExternalAccount() {
        require(externalAccount != address(0), "noext");
        require(msg.sender == externalAccount, "invacct");
        _;
    }
}
