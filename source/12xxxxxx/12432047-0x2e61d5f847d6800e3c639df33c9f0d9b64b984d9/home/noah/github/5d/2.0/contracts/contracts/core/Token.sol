pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is Ownable, ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply
    ) Ownable() ERC20(name, symbol) {
        _mint(msg.sender, totalSupply);
    }
}

