// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

import "./SafeMath.sol";
import "./IERC20.sol";

contract MintingFeeAndDAOLocked {
    using SafeMath for uint256;
    uint256 public startTime;
    address public sts;
    uint256 private lockDuration = 180 days;
    address public owner;
   

    constructor(address _sts,uint256 _startTime) public {
        owner = msg.sender;
        sts = _sts;
        startTime = _startTime;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    function unlockFeeAndDao(address _address) public onlyOwner {
        uint256 _now = block.timestamp;
        require(_now.sub(startTime) >= lockDuration, "The reward is still locked!");
        uint256 balance = IERC20(sts).balanceOf(address(this));
        IERC20(sts).transfer(_address, balance);
    }

}
