// SPDX-License-Identifier: DOGE WORLD
pragma solidity ^0.8.0;

struct JoinPartyInstruction
{
    uint256 amount;
    uint256 instructionId;
    address to;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface IDogecoin
{
    event DogeCrossingBridge(address indexed controller, uint256 amount);
    event DogeJoinedTheParty(uint256 indexed instructionId, address indexed recipient, uint256 amount);
    event Minter(address indexed minter, bool canMint);

    function instructionFulfilled(uint256 _instructionId) external view returns (bool);
    function minters(address _minter) external view returns (bool);

    function joinParty(address _to, uint256 _amount, uint256 _instructionId, uint8 _v, bytes32 _r, bytes32 _s) external;
    function multiJoinParty(JoinPartyInstruction[] calldata _instructions) external;
    function crossBridge(address _controller, uint256 _amount) external;
}
