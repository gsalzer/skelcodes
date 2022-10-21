pragma solidity >=0.4.21 <0.6.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Capped.sol";
import "./ERC20Burnable.sol";

contract SFtoken is ERC20, ERC20Detailed, ERC20Burnable {

    event CreateTokenSuccess(address owner, uint256 balance);

    uint256 amount = 2100000000;
    constructor(
    )
    ERC20Burnable()
    ERC20Detailed("ERM", "ERM", 18)
    ERC20()
    public
    {
        _mint(msg.sender, amount * (10 ** 18));
        emit CreateTokenSuccess(msg.sender, balanceOf(msg.sender));
    }
}

