// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./LiquidityLockedERC20.sol";
import "./IAmGroot.sol";

/* GROOTKIT:
Direct from Professor Ponzo's lab
*/

contract GrootKit is LiquidityLockedERC20("GrootKit", "GROOT"), IAmGroot
{
    constructor()
    {
        _mint(msg.sender, 1000000 ether);
    }

    function isGroot() public pure override returns (bool) { return true; }

    function burn() public
    {
        _burn(msg.sender, _balanceOf[msg.sender]);
    }
}
