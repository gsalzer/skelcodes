// SPDX-License-Identifier: MIT

/*
*
* Group Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* To be used in conjuction with VerifySignature as a way to validate a signature generated off-chain
*
*/

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Group is Ownable {

    string public group = "init";

    event GroupUpdated(string _group);

    function setGroup(string memory _grp) public onlyOwner {
        group = _grp;
        emit GroupUpdated(_grp);
    }
}
