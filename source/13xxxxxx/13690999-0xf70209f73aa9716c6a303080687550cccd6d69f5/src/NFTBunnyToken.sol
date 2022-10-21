pragma solidity ^0.8.10;

import {ERC20, ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract NFTBunnyToken is ERC20Permit, ERC20Burnable, Ownable {
    constructor(uint256 initialAmount) ERC20("NFTBunny", "BUN") ERC20Permit("NFTBunny") Ownable() {
        _mint(_msgSender(), initialAmount);
    }

    function mint(uint256 amount) external onlyOwner {
        _mint(_msgSender(), amount);
    }

    function mintTo(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }
}

