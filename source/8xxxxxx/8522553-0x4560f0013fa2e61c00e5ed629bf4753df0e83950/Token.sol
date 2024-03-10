pragma solidity ^0.5.0;

import "./ERC20.sol";


contract Token is ERC20 {
    string public constant name = "SportsplexToken";
    string public constant symbol = "SPX";
    uint8  public constant decimals = 8;

    constructor() public {
        uint256 supply = (10 ** 9);
        _mint(msg.sender, supply.mul(10 ** uint256(decimals)));
    }
}

