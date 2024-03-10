//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LLTH is ERC20, Ownable {
    mapping(address => bool) public managers;

    constructor() ERC20("Lilith", "LLTH") {
        managers[owner()] = true;
        _mint(owner(), 1000000 * (10**18));
    }

    /**@dev Allows execution by managers only */
    modifier managerOnly() {
        require(managers[msg.sender]);
        _;
    }

    /**@dev Be careful setting new manager, recheck the address */
    function setManager(address manager, bool state) external onlyOwner {
        managers[manager] = state;
    }

    /**@dev External mint for l1-l2 affairs */
    function mint(address user, uint256 amount) external managerOnly {
        _mint(user, amount);
    }

    /**@dev External burn for l1-l2 affairs */
    function burn(address user, uint256 amount) public managerOnly {
        _burn(user, amount);
    }
}

