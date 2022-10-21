pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";

contract ClaimPriorityDate {
    using SafeMath for uint256;
    
    mapping(address => uint) public weiDeposited;  
    mapping(address => uint) public priorityDate;
    
    string purpose;
    address owner;
    bool isEnabled;
    uint startDate;
    
    constructor(string memory _purpose) {
        owner = msg.sender;
        isEnabled = true;
        purpose = _purpose;
        startDate = block.timestamp;
    }
    
    function permanentlyDisable() public {
        require(msg.sender == owner);
        isEnabled = false;
    }
    
    function depositClaim() public payable {
        require(isEnabled);
        require(weiDeposited[msg.sender] == 0); ///  You already have a deposit and this smart contract does not support multiple deposits with multiple Priority Dates. Either use a new Ethereum address to claim another (later) priority date. Or forfeit your current priority date by withdrawing to exactly zero and then depositing again"
        require(msg.value > 0, "You must deposit a positive amount.");
        weiDeposited[msg.sender] = weiDeposited[msg.sender].add(msg.value);
        priorityDate[msg.sender] = block.timestamp;
    }
    
    receive() external payable {
        require(isEnabled);
        require(weiDeposited[msg.sender] == 0); ///  You already have a deposit and this smart contract does not support multiple deposits with multiple Priority Dates. Either use a new Ethereum address to claim another (later) priority date. Or forfeit your current priority date by withdrawing to exactly zero and then depositing again"
        require(msg.value > 0, "You must deposit a positive amount.");
        weiDeposited[msg.sender] = weiDeposited[msg.sender].add(msg.value);
        priorityDate[msg.sender] = block.timestamp;
    }
    
    function withdrawClaim(uint _weiWithdraw) public {
        require( weiDeposited[msg.sender] >= _weiWithdraw, "You are trying to withdraw more wei than you deposited.");
        weiDeposited[msg.sender] = weiDeposited[msg.sender].sub( _weiWithdraw );
        msg.sender.transfer(_weiWithdraw);
    }
    
}    

