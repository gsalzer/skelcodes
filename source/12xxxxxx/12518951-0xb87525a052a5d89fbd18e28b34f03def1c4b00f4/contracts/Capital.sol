// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Capital is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for IERC20;

    constructor (uint256 initialSupply) ERC20("Capital", "CPL") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public pure override returns (uint8) {
        return 5;
    }

    function recoverToken(address tokenAddress, uint256 amount) public onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner(), amount);
    }
}

