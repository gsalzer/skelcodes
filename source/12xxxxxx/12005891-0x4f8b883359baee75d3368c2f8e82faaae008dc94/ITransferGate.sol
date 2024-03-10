// SPDX-License-Identifier: P-P-P-PONZO!!!
pragma solidity ^0.7.4;

interface ITransferGate
{
    function handleTransfer(address msgSender, address from, address to, uint256 amount) external returns (address, uint256);
}
