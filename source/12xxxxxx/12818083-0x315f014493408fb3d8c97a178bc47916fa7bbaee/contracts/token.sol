// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MainToken is ERC20, ERC20Burnable, Ownable {
    string depositAddress = "0000000000000000000000000000000000";

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol) {
        _mint(msg.sender, 10 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 8;
    }


    function setDepositAddress(string memory depositAdr) public onlyOwner {
        depositAddress = depositAdr;
    }

    function getDepositAddress() public view returns (string memory) {
        return depositAddress;
    }

}

