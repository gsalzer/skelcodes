// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts@4.2.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts@4.2.0/access/Ownable.sol";
import "@openzeppelin/contracts@4.2.0/security/Pausable.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts@4.2.0/token/ERC20/extensions/ERC20FlashMint.sol";

contract DyneCoin is ERC20, ERC20Burnable, ERC20Snapshot, Ownable, Pausable, ERC20Permit, ERC20Votes, ERC20FlashMint {
    constructor() ERC20("DyneCoin", "DYNE") ERC20Permit("DyneCoin") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }
}

