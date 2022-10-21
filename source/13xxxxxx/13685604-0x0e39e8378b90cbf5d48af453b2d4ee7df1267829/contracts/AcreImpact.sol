// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract AcreImpact is
    Initializable,
    ERC20BurnableUpgradeable,
    ERC20CappedUpgradeable,
    OwnableUpgradeable
{

    function initialize(uint256 supplyCap) 
        public 
        initializer 
    {
        OwnableUpgradeable.__Ownable_init();
        ERC20BurnableUpgradeable.__ERC20Burnable_init();
        ERC20CappedUpgradeable.__ERC20Capped_init(supplyCap);
        ERC20Upgradeable.__ERC20_init("ACRE Impact", "ACRE");
    }

    /** @dev Creates `amount` tokens and assigns them to address `to`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address to, uint256 amount) 
        public 
        onlyOwner 
    {
        super._mint(to, amount);
    }

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount)
        internal 
        virtual 
        override(ERC20CappedUpgradeable, ERC20Upgradeable) 
    {
        require(ERC20Upgradeable.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }

}
