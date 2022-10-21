// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Functions {

  function mintFreeAscii() external;

  function mintPaidAscii(uint256 quantity) external payable;

  function mintToWallet(address _0x) external;

  function freeMintTotal(address owner) external returns (uint256);

  function paidMintTotal(address owner) external returns (uint256);

  function ContractSwitch(bool isMasterActive) external;

  function withdraw() external;

}

