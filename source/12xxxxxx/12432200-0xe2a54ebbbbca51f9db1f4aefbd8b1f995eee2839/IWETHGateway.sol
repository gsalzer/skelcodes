// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IWETHGateway {
  function depositETH(address onBehalfOf) external payable;

  function withdrawETH(uint256 amount, address onBehalfOf) external;

  function borrowETH(
    uint256 amount
  ) external;
}

