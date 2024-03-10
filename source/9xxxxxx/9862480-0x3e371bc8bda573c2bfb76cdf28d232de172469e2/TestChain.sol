pragma solidity ^0.6.6;

import "./ERC20Pausable.sol";

/**
 * @title Pausable token
 * @dev ERC20 modified with pausable transfers.
 **/
contract TestChain is ERC20Pausable {
    string public constant name = "TestChain";
    uint8 public constant decimals = 18;
    string public constant symbol = "TCN";
    
    constructor() public {
        _mint(msg.sender, 4900000000 * 1000000000000000000);
    }
}
