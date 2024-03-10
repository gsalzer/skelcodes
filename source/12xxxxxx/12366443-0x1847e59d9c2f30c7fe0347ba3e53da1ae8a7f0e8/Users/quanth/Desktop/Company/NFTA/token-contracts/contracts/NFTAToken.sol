// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract NFTAToken is ERC20, ERC20Capped, ERC20Burnable {
    uint public constant HARD_CAP = 100_000_000e18; // 100m token

    /**
     * @dev Constructor function of NFTA Token
     * @dev set name, symbol and decimal of token
     * @dev mint totalSupply (cap) to address
     */
    constructor (
    ) public ERC20("NFTA Token", "NFTA") ERC20Capped(HARD_CAP) {
        _setupDecimals(18);
        _mint(0xB4A375244E56e57D31866b19BC1F5ad60875BcB4, HARD_CAP);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20, ERC20Capped) {
        super._beforeTokenTransfer(from, to, amount);
    }

}
