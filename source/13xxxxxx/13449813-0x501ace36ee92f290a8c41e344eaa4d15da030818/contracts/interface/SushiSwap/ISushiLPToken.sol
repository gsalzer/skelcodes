// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

interface ISushiLPToken {
 
  /**
   * @notice Returns the address of `SushiFactory`.
   * @return factory The address of the factory.
   */
  function factory() external view returns (address factory);
  
  /**
   * @notice Returns the first pair token.
   * @return token The address of the first pair token.
   */
  function token0() external view returns (address token);

  /**
   * @notice Returns the second pair token.
   * @return token The address of the second pair token.
   */
  function token1() external view returns (address token);

  /**
   * @notice Returns the symbol of the token.
   * @return symbol The token symbol.
   */
  function symbol() external view returns (string memory symbol);

  /**
   * @notice Returns the name of the token.
   * @return name The token name.
   */
  function name() external view returns (string memory name);

  /**
   * @notice Returns total token supply.
   * @return totalSupply The total supply.
   */
  function totalSupply() external view returns (uint256 totalSupply);

  /**
   * @notice Returns account's balance.
   * @param account The address of the user.
   * @return balance The amount tokens user have.
   */
  function balanceOf(address account) external view returns (uint256 balance);

  /**
  * @notice Returns the decimals value.
  * @return decimals The decimals value.
  */
  function decimals() external view returns (uint256);
}

