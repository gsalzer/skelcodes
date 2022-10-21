pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Telemedicoin is ERC20 {
 
    constructor() ERC20("Telemedicoin", "TTC") public {
        _mint(msg.sender, 100 * 10 ** 6 * 10 ** uint(decimals()));
    }
}

