// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

/* ROOTKIT:
A floor calculator (to use with ERC31337)
This one is for liquidity tokens
So finally
WE CAN PLAY JENGA
*/

import "./IFloorCalculator.sol";
import "./TokensRecoverable.sol";

contract RootKitRuggableFloorCalculator is IFloorCalculator, Owned, TokensRecoverable
{
    uint256 subFloor;

    function setSubFloor(uint256 _subFloor) public ownerOnly()
    {
        subFloor = _subFloor;
    }

    function calculateSubFloor(IERC20, IERC20) public override view returns (uint256)
    {
        return subFloor;
    }
}
