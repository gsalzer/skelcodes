pragma solidity ^0.5.0;

import "./IERC20.sol";


contract Lockup {
    address public owner;
    uint256 public lockupExpiryDate;

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }

    constructor(uint256 lockupExpiryDate_) public {
        owner = msg.sender;
        lockupExpiryDate = lockupExpiryDate_;
    }

    function transfer(address token, address to, uint256 amount) public onlyOwner {
        require(now > lockupExpiryDate, "lockup period is not over");
        IERC20(token).transfer(to, amount);
    }
}

