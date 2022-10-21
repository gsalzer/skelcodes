// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./IOwned.sol";
import "./IRootKitDistribution.sol";

interface IStoneface
{
    event PendingOwnershipTransfer(IOwned target, address newOwner, uint256 when);

    struct TransferOwnership
    {
        uint256 when;
        IOwned target;
        address newOwner;
    }

    function delay() external view returns (uint256);
    function pendingTransferOwnership(uint256 index) external view returns (TransferOwnership memory);
    function pendingTransferOwnershipCount() external view returns (uint256);
    function callTransferOwnership(IOwned target, address newOwner) external;
    function callTransferOwnershipNow(uint256 index) external;
    function callClaimOwnership(IOwned target) external;
    function rootKitDistribution() external view returns (IRootKitDistribution);
    function watchDistribution(IRootKitDistribution _rootKitDistribution) external;
}
