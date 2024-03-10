// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.7.0;

interface IProxyCall {
  function proxyCallAndReturnAddress(address externalContract, bytes calldata callData)
    external
    returns (address payable result);
}

