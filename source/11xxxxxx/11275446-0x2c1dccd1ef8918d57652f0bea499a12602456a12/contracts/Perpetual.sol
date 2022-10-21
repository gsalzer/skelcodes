pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PerpetualContract is ERC20 {
    constructor(
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) public ERC20(name, symbol) {
        _mint(msg.sender, initialSupply);
    }
}
