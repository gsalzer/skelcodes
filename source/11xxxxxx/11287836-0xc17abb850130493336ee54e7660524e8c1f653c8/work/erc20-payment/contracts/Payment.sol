// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Payment {
    address public owner;
    IERC20 public token;

    constructor(address tokenAddress_) public {
        owner = msg.sender;
        token = IERC20(tokenAddress_);
    }

    function pay(string memory ref, uint256 amount)
        external
        returns (bool result)
    {
        result = token.transferFrom(msg.sender, owner, amount);
        require(result, "PaymentFailed");
        emit PaymentDone(ref, msg.sender, amount, block.timestamp);
        return true;
    }

    function transferOwnership(address newOwner_) public restricted {
        owner = newOwner_;
        emit OwnerChanged(msg.sender, newOwner_);
    }

    // Modifier: Allows only
    modifier restricted() {
        require(msg.sender == owner, "Forbidden");
        _;
    }

    // Event: Fired when payment done.
    event PaymentDone(string ref, address payer, uint256 amount, uint256 date);

    // Event: Fired when owner changed.
    event OwnerChanged(address oldOwner, address newOwner);
}

