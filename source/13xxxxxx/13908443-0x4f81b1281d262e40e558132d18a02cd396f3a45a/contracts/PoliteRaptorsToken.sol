// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PoliteRaptorsToken is ERC20, ERC20Burnable, Ownable {
    modifier onlyMinter() {
        require(msg.sender == minter, "Not allowed");
        _;
    }

    modifier minterNotLocked() {
        require(!minterLocked, "Minter locked");
        _;
    }

    address public minter;
    bool public minterLocked;

    constructor() ERC20("PoliteRaptorsToken", "PRP") {}

    function mint(address to, uint256 amount) external onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address newMinter) external onlyOwner minterNotLocked {
        minter = newMinter;
    }

    function lockMinter() external onlyOwner minterNotLocked {
        minterLocked = true;
    }
}

