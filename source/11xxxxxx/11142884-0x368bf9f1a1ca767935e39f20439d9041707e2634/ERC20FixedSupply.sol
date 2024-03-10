pragma solidity ^0.4.24;

import "./ERC20.sol";

contract ERC20FixedSupply is ERC20 {
    constructor(uint tokens) public {
        _mint(msg.sender, tokens);
    }
}
