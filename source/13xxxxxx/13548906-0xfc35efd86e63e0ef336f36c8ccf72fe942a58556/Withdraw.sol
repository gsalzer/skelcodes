// SPDX-License-Identifier: MIT

/*
*
* Withdraw Contract
* 
* Contract by Matt Casanova [Twitter: @DevGuyThings]
* 
* Withdraw funds from a contract
*
*/

pragma solidity 0.8.9;

import "./Ownable.sol";

contract Withdraw is Ownable {
    function seeBalance() public view onlyOwner returns(uint)  {
        return address(this).balance;
    }

    function withdraw(address payable _to, uint _amount) public onlyOwner returns(bool)  {
        require(_amount <= address(this).balance, "insfnds");
        _to.transfer(_amount);
        return true;
    }
}
