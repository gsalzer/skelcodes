// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

interface ILootBox {
  function afterHarbergerBuy(uint256 _tokenId, address _newOwner) external;
}

