pragma solidity ^0.5.1;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
// ----------------------------------------------------------------------------
// 'Tcbcoin' token contract
//
// Deployed to : 0x36dCffe069a3F2878Fab2A46D81e83D462d0cBF7
// Symbol      : TCFX
// Name        : Tcbcoin
// Total supply: 50000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by Tcbcoin Team.  The MIT Licence.
// ----------------------------------------------------------------------------

contract Tcbcoin is ERC20, ERC20Detailed, ERC20Burnable {
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY = 50000000 * (10 ** uint256(DECIMALS));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor () public ERC20Detailed("Tcbcoin", "TCFX", DECIMALS) {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
   
}

