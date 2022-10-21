pragma solidity ^0.5.5;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";
import "../node_modules/@openzeppelin/contracts/ownership/Ownable.sol";

contract Token is Context, ERC20, ERC20Detailed, ERC20Burnable, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) public ERC20Detailed(name, symbol, 18) {
        _mint(_msgSender(), initialSupply);
    }
}
