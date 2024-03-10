// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./erc/ERC20.sol";
import "./lib/Ownable.sol";
import "./IGains.sol";

contract Gains is ERC20, Ownable, IGains {

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;

    constructor() ERC20("Gains", "GAINS") {}

    /**
     * mints $GAINS to a recipient
     * @param to the recipient of the $GAINS
   * @param amount the amount of $GAINS to mint
   */
    function mint(address to, uint256 amount) external override {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    /**
     * burns $GAINS from a holder
     * @param from the holder of the $GAINS
   * @param amount the amount of $GAINS to burn
   */
    function burn(address from, uint256 amount) external override {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
   */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
   */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}

