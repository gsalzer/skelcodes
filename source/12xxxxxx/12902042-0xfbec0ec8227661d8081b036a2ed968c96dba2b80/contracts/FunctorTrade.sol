// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ENV.sol" as ENV;

//   ______                _                   _______            _      
//  |  ____|              | |                 |__   __|          | |     
//  | |__ _   _ _ __   ___| |_ ___  _ __         | |_ __ __ _  __| | ___ 
//  |  __| | | | '_ \ / __| __/ _ \| '__|        | | '__/ _` |/ _` |/ _ \
//  | |  | |_| | | | | (__| || (_) | |     _     | | | | (_| | (_| |  __/
//  |_|   \__,_|_| |_|\___|\__\___/|_|    (_)    |_|_|  \__,_|\__,_|\___|
                                                                      
                                                                      
contract FunctorTrade is ERC20, ERC20Burnable, Pausable, Ownable {
      
    constructor() ERC20(ENV.name, ENV.symbol) {
        _mint(msg.sender, ENV.initialSupply);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }
}

 
                                                                      
                                                                      
