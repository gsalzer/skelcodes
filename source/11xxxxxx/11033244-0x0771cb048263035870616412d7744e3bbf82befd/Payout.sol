pragma solidity ^0.6.1;

contract Payout
{
address payable public address1 = 0x8dDd4c51a5dCfb83E070f04bF5C4F98b3FdA6977;
address payable public address2 = 0x2aAB156B5586FB0028a0Afe9250554317669ADcf;
address payable public address3 = 0xC27e4bb236E163e4A2e91D483891DF6801d7342F;
address public owner = 0x482F222e30D49BF9606a0F6DEa7c210698B367F9;
	
uint256 public address1share = 7250;
uint256 public address2share = 1250;
uint256 public address3share = 1500;

uint256 public previousPayouts = 29315110000000000000;
uint256 public countPayouts = 0;

receive() external payable
{
	
}

function triggerPayouts() payable public
{
	if(!address1.send(msg.value * address1share / 100 / 100)) revert();
	if(!address2.send(msg.value * address2share / 100 / 100)) revert();
	if(!address3.send(msg.value * address3share / 100 / 100)) revert();
	countPayouts += msg.value;
}

function transferAllFundsOut(address payable _address) payable public
{
	if (msg.sender == owner)
		if(!_address.send(msg.value))
			revert();	
}

function totalPayouts() view public returns (uint256)
{
	return previousPayouts + countPayouts;
}
}
