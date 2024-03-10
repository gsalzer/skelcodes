// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator (to use with ERC31337)
This one is for liquidity tokens
So finally
WE CAN PLAY JENGA
*/

import "./IFloorCalculatorDelux.sol";
import "./TokensRecoverable.sol";

contract RootkitRuggableFloorCalculatorDelux is IFloorCalculatorDelux, TokensRecoverable
{
    uint256 subFloor;
    mapping (address => bool) public floorSetters;

    function setSubFloor(uint256 _subFloor) public override
    {
        require (msg.sender == owner || floorSetters[msg.sender], "You Wish!!!");
        subFloor = _subFloor;
    }

    function calculateSubFloor(IERC20, IERC20) public override view returns (uint256)
    {
        return subFloor;
    }
    function setFloorSetter(address setterAddress, bool setterStatus) public ownerOnly() 
    {
        floorSetters[setterAddress] = setterStatus;
    }

}
