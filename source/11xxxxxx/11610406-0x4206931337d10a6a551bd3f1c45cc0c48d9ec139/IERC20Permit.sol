// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IERC20Permit is IERC20
{
    function permit(address _owner, address _spender, uint256 _amount, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;
}
