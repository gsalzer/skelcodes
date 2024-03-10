/*
Fair gambling. No admin backdoor. No etherscan bugs. No shit. Just fair play.
Deposit and wait for deposit multiplication. If you dare.

Deposit will grow up to x2 during 100 blocks.
If you failed withdraw attempt, deposit will disappear.
If you wait more then 100 blocks, deposit will disappear.

You may use any bots/automation except calling from smart-contract.
*/

pragma solidity ^0.5;

contract FairDare {
    mapping (address => uint) depositAmount;
    mapping (address => uint) depositBlock;
    
    function() external payable {
        depositBlock[msg.sender] = block.number;
        depositAmount[msg.sender] = msg.value;
    }
    
    function withdraw() public {
        require(tx.origin == msg.sender, "calling from smart is not allowed");

        uint blocksPast = block.number - depositBlock[msg.sender];
        
        if (blocksPast <= 100) {
            uint amountToWithdraw = depositAmount[msg.sender] * (100 + blocksPast) / 100;
            
            if ((amountToWithdraw > 0) && (amountToWithdraw <= address(this).balance)) {
                msg.sender.transfer(amountToWithdraw);
                depositAmount[msg.sender] = 0;
            }
        }
    }
}
