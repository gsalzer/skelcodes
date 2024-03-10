pragma solidity ^0.5.0;

import "./ERC20Burnable.sol";
import "./ERC20Detailed.sol";

contract AAXToken is ERC20Burnable, ERC20Detailed {

    constructor() public
        ERC20Detailed("AAX Token", "AAB", 18)
    {
        _mint(
            msg.sender,
            50000000 * (10 ** uint256(decimals()))
        );
    }

}



