// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract OtoCoToken is ERC20, ERC20Burnable, Ownable {
    uint8 _decimals;

    constructor(string memory name_, string memory symbol_, uint256 supply_, uint8 decimals_) ERC20(name_, symbol_) Ownable() {
        _decimals = decimals_;
        _mint(msg.sender, supply_);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mint(address account, uint256 amount) public onlyOwner returns (bool) {
        _mint(account, amount);
        return true;
    }
}

