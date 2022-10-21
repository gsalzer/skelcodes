// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface IUniV2Factory {

  /**
   * @notice Returns `LP Pool` length.
   * @return pools The number of pools.
   */
  function allPairsLength() external view returns (uint256 pools);
  
  /**
   * @notice Returns `LP Pool` address.
   * @param pairIndex The index of the lp pair.
   * @return pair The address of the lp pair.
   */
  function allPairs(uint256 pairIndex) external view returns (address pair);
  
  /**
   * @notice Gets the `LP Pool` for given input pair `token0` and `token1`
   * @param token0 The pair first token.
   * @param token1 The pair second token.
   * @return pair The address of the pair.
   */
  function getPair(address token0, address token1) external view returns (address pair);
}
