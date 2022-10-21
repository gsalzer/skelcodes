// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TrashFunctions {

  function mintTrash(uint256 numberOfTokens) external payable;
    function mintTrashReserve(uint256 numberOfTokens) external payable;


  function MasterActive(bool isMasterActive) external;

  function BurnActive(bool isMasterActive) external;

  function withdraw() external;
}
