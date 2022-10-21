// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <= 0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract MOEToken is Initializable, ERC20Upgradeable {

    function initialize(string memory name, string memory symbol, uint256 initialSupply) public virtual initializer {
        __ERC20_init(name, symbol);
        _mint(_msgSender(), initialSupply);
    
    }

}
