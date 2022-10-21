// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BagToken is ERC20Capped, Ownable {
    
    constructor(uint256 _hard_cap) ERC20("LootArt Gold", "LAGLD") ERC20Capped(_hard_cap) {
        
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
