// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.12;

/**
 * @title ITokenConfiguration
 * @author Lever
 * @dev Common interface between xTokens and debt tokens to fetch the
 * token configuration
 **/
interface ITokenConfiguration {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  function POOL() external view returns (address);
}

