// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

import "./ISafelyOwned.sol";
import "./SafeERC20.sol";

abstract contract SafelyOwned is ISafelyOwned
{
    using SafeERC20 for IERC20;
    
    address public override owner = msg.sender;
    address internal pendingOwner;

    modifier ownerOnly()
    {
        require (msg.sender == owner, "Owner only");
        _;
    }

    function transferOwnership(address _newOwner) public override ownerOnly()
    {
        pendingOwner = _newOwner;
    }

    function claimOwnership() public override
    {
        require (pendingOwner == msg.sender);
        pendingOwner = address(0);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
    }

    function recoverTokens(IERC20 _token) public override ownerOnly() 
    {
        require (canRecoverTokens(_token));
        _token.safeTransfer(msg.sender, _token.balanceOf(address(this)));
    }

    function canRecoverTokens(IERC20 _token) internal virtual view returns (bool) 
    { 
        return address(_token) != address(this); 
    }

    function recoverETH() public override ownerOnly()
    {
        require (canRecoverETH());
        (bool success,) = msg.sender.call{ value: address(this).balance }("");
        require (success, "Transfer fail");
    }

    function canRecoverETH() internal virtual view returns (bool) 
    {
        return true;
    }
}
