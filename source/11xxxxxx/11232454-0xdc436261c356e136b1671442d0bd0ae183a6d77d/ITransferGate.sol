// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

struct TransferGateTarget
{
    address destination;
    uint256 amount;
}

interface ITransferGate
{
    function handleTransfer(address msgSender, address from, address to, uint256 amount) external
        returns (uint256 burn, TransferGateTarget[] memory targets);
}
