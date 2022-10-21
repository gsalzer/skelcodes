// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";

contract RootKitVault is Owned
{
    using SafeERC20 for IERC20;
    
    receive() external payable { }

    function sendEther(address payable _to, uint256 _amount) public ownerOnly()
    {
        (bool success,) = _to.call{ value: _amount }("");
        require (success, "Transfer failed");
    }

    function sendToken(IERC20 _token, address _to, uint256 _amount) public ownerOnly()
    {
        _token.safeTransfer(_to, _amount);
    }
}
