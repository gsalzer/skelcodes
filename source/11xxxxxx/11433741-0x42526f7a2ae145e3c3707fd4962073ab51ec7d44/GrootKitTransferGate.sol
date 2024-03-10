// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./ITransferGate.sol";
import "./TokensRecoverable.sol";
import "./GrootToRoot.sol";
import "./GrootGrower.sol";

contract GrootKitTransferGate is TokensRecoverable, ITransferGate
{
    uint16 public burnPercent; // 100% = 10000
    uint16 public grootToRootPercent;
    GrootToRoot public grootToRoot;
    GrootGrower public grootGrower;

    function setParameters(GrootGrower _grootGrower, GrootToRoot _grootToRoot, uint16 _grootToRootPercent, uint16 _burnPercent) public ownerOnly()
    {
        grootGrower = _grootGrower;
        grootToRoot = _grootToRoot;
        grootToRootPercent = _grootToRootPercent;
        burnPercent = _burnPercent;
    }

    function handleTransfer(address, address from, address to, uint256 amount) external override view
        returns (uint256 burn, TransferGateTarget[] memory targets)
    {
        GrootToRoot _grootToRoot = grootToRoot;
        GrootGrower _grootGrower = grootGrower;
        if (from == address(_grootToRoot) || to == address(_grootToRoot) || amount == 0 || from == address(_grootGrower) || to == address(_grootGrower)) {
            return (0, new TransferGateTarget[](0));
        }
        burn = amount * burnPercent / 10000;
        uint256 toGrootToRoot = amount * grootToRootPercent / 10000;
        if (address(_grootToRoot) == address(0) || toGrootToRoot == 0) {
            return (burn, new TransferGateTarget[](0));
        }
        targets = new TransferGateTarget[](1);
        targets[0].destination = address(grootToRoot);
        targets[0].amount = toGrootToRoot;
    }
}
