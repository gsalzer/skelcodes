// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface ISyntLayer {
  function rebalanceLiquidity (  ) external;
  function rebalanceable (  ) external view returns ( bool );
  function minRebalanceAmount (  ) external view returns ( uint256 );
}
