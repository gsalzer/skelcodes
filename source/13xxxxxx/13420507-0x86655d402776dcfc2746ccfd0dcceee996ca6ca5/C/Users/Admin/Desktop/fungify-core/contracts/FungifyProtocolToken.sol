// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "./ERC20FungifyCapitalization.sol";

contract FungifyProtocolToken is
    ERC20("Fungify Protocol Token", "FUNG"),
    ERC20Burnable,
    ERC20Permit("Fungify Protocol Token"),
    ERC20Votes,
    ERC20FungifyCapitalization
{

    /**
     * @dev Constructor for the FUNG ERC-20 token.
     * @param _treasuryAddress The address of the Fungify treasury/timelock contract.
     */
    constructor(
        address _treasuryAddress
    )
    ERC20FungifyCapitalization(_treasuryAddress)
    // solhint-disable-next-line no-empty-blocks
    {}

    // The functions below are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC20, ERC20FungifyCapitalization)
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
