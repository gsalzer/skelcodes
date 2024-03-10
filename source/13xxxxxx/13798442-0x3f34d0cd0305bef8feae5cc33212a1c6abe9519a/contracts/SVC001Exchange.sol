//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SVC001Exchange is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable token;
    bool public isOperative;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    event Received(address indexed sender, uint indexed amount);
    event Claimed(address indexed sender, uint indexed amount);
    event Withdrawn(address indexed sender, uint indexed amount);

    constructor(address token_) {
        token = token_;
    }

    function setIsOperative(bool _isOperative) public onlyOwner {
        isOperative = _isOperative;
    }

    function claim(uint claimAmount) external {
        require(isOperative, "Is not operative");
        uint contractBalance = address(this).balance;

        uint totalEthAmount = 1574 ether;
        uint tokenTotalSupply = 20794780999725;

        uint ethAmount = totalEthAmount * claimAmount / tokenTotalSupply;

        require(contractBalance >= ethAmount, "Contract out of balance");

        IERC20(token).safeTransferFrom(msg.sender, burnAddress, claimAmount);

        _safeTransferETH(msg.sender, ethAmount);

        emit Claimed(msg.sender, claimAmount);
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw(uint amount) public onlyOwner {
        _safeTransferETH(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function _safeTransferETH(address to, uint value) private {
        (bool success, ) = to.call{value: value}("");
        require(success, "Failed to transfer Ether");
    }
}

