// SPDX-License-Identifier: J-J-J-JENGA!!!
pragma solidity ^0.7.4;

import "./Owned.sol";

contract FreeParticipantRegistry is Owned
{
    address public transferGate;
    mapping (address => bool) public freeParticipantControllers;
    mapping (address => bool) public freeParticipant;

    modifier transferGateOnly()
    {
        require (msg.sender == transferGate, "Transfer Gate only");
        _;
    }

    function setTransferGate(address _transferGate) public ownerOnly()
    {
        transferGate = _transferGate;
    }

    function setFreeParticipantController(address freeParticipantController, bool allow) public transferGateOnly()
    {
        freeParticipantControllers[freeParticipantController] = allow;
    }

    function setFreeParticipant(address participant, bool free) public transferGateOnly()
    {
        freeParticipant[participant] = free;
    }
}
