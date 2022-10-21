// SPDX-License-Identifier: MIT
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.12;

interface IPriceModel {  
  /// @dev Get current price per token
  function price() external view returns (uint256);

  /// @dev Get startBlock from price model
  function startBlock() external view returns (uint256);

  /// @dev Get endBlock from price model
  function endBlock() external view returns (uint256);
}

