// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ISafelyOwned
{
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function transferOwnership(address _newOwner) external;
    function claimOwnership() external;
    function recoverTokens(IERC20 _token) external;
    function recoverETH() external;
}
