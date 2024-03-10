pragma solidity ^0.6.0;
import './Ownable.sol';
import './SafeMath.sol';
// SPDX-License-Identifier: UNLICENSED

contract CrowdConfigurableSale is Ownable {
    using SafeMath for uint256;

    // start and end date where investments are allowed (both inclusive)
    uint256 public startDate; 
    uint256 public endDate;

    // Minimum amount to participate
    uint256 public minimumParticipationAmount;

    uint256 public minimumToRaise;

    // address where funds are collected
    address payable public wallet;

    // Pancakeswap pair address for BNB and Token
    address public chainLinkAddress;
    
    //cap for the sale
    uint256 public cap; 

    // amount of raised money in wei
    uint256 public weiRaised;

    //flag for final of crowdsale
    bool public isFinalized = false;
    bool public isCanceled = false;

    
    function getChainlinkAddress() public view returns (address) {
        return chainLinkAddress;
    }
    
    function isStarted() public view returns (bool) {
        return startDate <= block.timestamp;
    }

    function changeStartDate(uint256 _startDate) public onlyAdmin {
        startDate = _startDate;
    }

    function changeEndDate(uint256 _endDate) public onlyAdmin {
        endDate = _endDate;
    }
}

