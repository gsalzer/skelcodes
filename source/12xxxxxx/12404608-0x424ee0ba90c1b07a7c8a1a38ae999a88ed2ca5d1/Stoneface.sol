// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

/* ROOTKIT:
Stoneface will protect you
Stoneface will hold stuff
Like KETH
But it doesn't know anything
So it can't call setFloorCalculator
Or setSweeper
Or anything, really
It's pretty stupid
But it'll give stuff back if we want
And if we're patient enough
Cus it takes a while
Unless we tell it to watch the distribution
Then he wont give it back at all
Unless the distribution is complete
Stoneface is slow
*/

import "./Owned.sol";
import "./TokensRecoverable.sol";
import "./IStoneface.sol";
import "./IRootKitDistribution.sol";

contract Stoneface is TokensRecoverable, IStoneface
{
    uint256 public immutable override delay;

    IRootKitDistribution public override rootKitDistribution;

    TransferOwnership[] _pendingTransferOwnership;
    function pendingTransferOwnership(uint256 index) public override view returns (TransferOwnership memory) { return _pendingTransferOwnership[index]; }
    function pendingTransferOwnershipCount() public override view returns (uint256) { return _pendingTransferOwnership.length; }

    constructor(uint256 _delay)
    {
        delay = _delay;
    }

    function watchDistribution(IRootKitDistribution _rootKitDistribution) public override ownerOnly()
    {
        require (address(rootKitDistribution) == address(0), "Can only be set once");
        rootKitDistribution = _rootKitDistribution;
    }

    function callTransferOwnership(IOwned target, address newOwner) public override ownerOnly()
    {
        TransferOwnership memory pending;
        pending.target = target;
        pending.newOwner = newOwner;
        pending.when = block.timestamp + delay;
        _pendingTransferOwnership.push(pending);
        emit PendingOwnershipTransfer(target, newOwner, pending.when);
    }

    function callTransferOwnershipNow(uint256 index) public override ownerOnly()
    {
        require (_pendingTransferOwnership[index].when <= block.timestamp, "Too early");
        require (address(rootKitDistribution) == address(0) || rootKitDistribution.distributionComplete(), "Distribution not yet complete");
        _pendingTransferOwnership[index].target.transferOwnership(_pendingTransferOwnership[index].newOwner);
        _pendingTransferOwnership[index] = _pendingTransferOwnership[_pendingTransferOwnership.length - 1];
        _pendingTransferOwnership.pop();
    }

    function callClaimOwnership(IOwned target) public override ownerOnly()
    {
        target.claimOwnership();
    }
}
