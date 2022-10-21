pragma solidity ^0.4.20;

contract Freemoney {

    function Freemoney() public payable
    {
        require(msg.value == 0.1 ether);
    }
    
    function extractMoney() public payable
    {
        require(msg.value == 0.1 ether);
        msg.sender.transfer(this.balance);
    }

}
