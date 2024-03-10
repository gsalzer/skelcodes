// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from './IERC20.sol';
import {DataTypes} from './DataTypes.sol';

/**
 * @title Helpers library
 * @author Lever
 */
library Helpers {
  /**
   * @dev Fetches the user current variable debt balances
   * @param user The user address
   * @param reserve The reserve data object
   * @return The variable debt balance
   **/
  function getUserCurrentDebt(address user, DataTypes.ReserveData storage reserve)
    internal
    view
    returns (uint256)
  {
    return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
  }

  function getUserCurrentDebtMemory(address user, DataTypes.ReserveData memory reserve)
    internal
    view
    returns (uint256)
  {
    return IERC20(reserve.variableDebtTokenAddress).balanceOf(user);
  }
}

