pragma solidity ^0.7.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RewardsVault is Ownable {

    IERC20 private _reignToken;

    constructor(address reignToken) {
        _reignToken = IERC20(reignToken);
    }

    event SetAllowance(
        address indexed caller,
        address indexed spender,
        uint256 amount
    );

    function setAllowance(address spender, uint256 amount) public onlyOwner {
        _reignToken.approve(spender, amount);

        emit SetAllowance(msg.sender, spender, amount);
    }
}

