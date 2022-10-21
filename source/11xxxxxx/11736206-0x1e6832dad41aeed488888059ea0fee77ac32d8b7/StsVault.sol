// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./ERC20.sol";

contract StsVault {
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    uint public applyTime;
    uint public applyAmount;
    ERC20 public STS;
    address owner_address;
    uint PERIOD = 3 days;

    modifier onlyOwner() {
        require(msg.sender == owner_address, "You are not an owner!");
        _;
    }

    constructor(address _sts) public {
        STS = ERC20(_sts);
        owner_address = msg.sender;
    }
    
    function applySts(uint _amount) public onlyOwner {
        applyTime = block.timestamp.add(PERIOD);
        applyAmount = _amount;
    }
    
    function getSts(address _address) public onlyOwner {
        require(block.timestamp > applyTime, "It's not time yet.");
        require(applyAmount>0,"Insufficient quantity");
        STS.safeTransfer(_address, applyAmount);
        applyAmount = 0;
    }

  
}

