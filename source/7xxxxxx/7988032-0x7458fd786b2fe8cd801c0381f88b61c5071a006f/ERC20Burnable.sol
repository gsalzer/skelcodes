pragma solidity ^0.5.0;

import "./ERC20.sol";

/**
 * @title LOAPROTOCOL

 */
contract ERC20Burnable is ERC20 {

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

