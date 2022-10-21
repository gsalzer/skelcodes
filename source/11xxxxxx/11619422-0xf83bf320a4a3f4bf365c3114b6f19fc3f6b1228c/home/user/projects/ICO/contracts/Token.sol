// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20Burnable, ERC20Capped, Ownable {

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        address ownerAddress
    ) ERC20(name, symbol) ERC20Capped(cap) {
        _setupDecimals(decimals);
        _mint(ownerAddress, cap);
        transferOwnership(ownerAddress);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20, ERC20Capped) {
        ERC20Capped._beforeTokenTransfer(from, to, amount);
    }

}

