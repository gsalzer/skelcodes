pragma solidity ^0.5.0;

import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";

contract BasicToken is ERC20Burnable, ERC20Detailed {

    constructor(string memory name, string memory symbol, uint8 decimals, uint256 total) public
        ERC20Detailed(name, symbol, decimals)
    {
        _mint(
            msg.sender,
            total * (10 ** uint256(decimals))
        );
    }

}



