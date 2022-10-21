// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {SafeMath} from './SafeMath.sol';
import {IReserveInterestRateStrategy} from './IReserveInterestRateStrategy.sol';
import {WadRayMath} from './WadRayMath.sol';
import {PercentageMath} from './PercentageMath.sol';
import {IMarginPoolAddressesProvider} from './IMarginPoolAddressesProvider.sol';

/**
 * @title DefaultReserveInterestRateStrategy contract
 * @notice Implements the calculation of the interest rates depending on the reserve state
 * @dev The model of interest rate is based on 2 slopes, one before the `OPTIMAL_UTILIZATION_RATE`
 * point of utilization and another from that one to 100%
 * @author Lever
 **/
contract DefaultReserveInterestRateStrategy is IReserveInterestRateStrategy {
  using WadRayMath for uint256;
  using SafeMath for uint256;
  using PercentageMath for uint256;

  /**
   * @dev this constant represents the utilization rate at which the pool aims to obtain most competitive borrow rates.
   * Expressed in ray
   **/
  uint256 public immutable OPTIMAL_UTILIZATION_RATE;

  /**
   * @dev This constant represents the excess utilization rate above the optimal. It's always equal to
   * 1-optimal utilization rate. Added as a constant here for gas optimizations.
   * Expressed in ray
   **/

  uint256 public immutable EXCESS_UTILIZATION_RATE;

  IMarginPoolAddressesProvider public immutable addressesProvider;

  // Base variable borrow rate when Utilization rate = 0. Expressed in ray
  uint256 internal immutable _baseVariableBorrowRate;

  // Slope of the variable interest curve when utilization rate > 0 and <= OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope1;

  // Slope of the variable interest curve when utilization rate > OPTIMAL_UTILIZATION_RATE. Expressed in ray
  uint256 internal immutable _variableRateSlope2;


  constructor(
    IMarginPoolAddressesProvider provider,
    uint256 optimalUtilizationRate,
    uint256 baseVariableBorrowRate,
    uint256 variableRateSlope1,
    uint256 variableRateSlope2
  ) public {
    OPTIMAL_UTILIZATION_RATE = optimalUtilizationRate;
    EXCESS_UTILIZATION_RATE = WadRayMath.ray().sub(optimalUtilizationRate);
    addressesProvider = provider;
    _baseVariableBorrowRate = baseVariableBorrowRate;
    _variableRateSlope1 = variableRateSlope1;
    _variableRateSlope2 = variableRateSlope2;
  }

  function variableRateSlope1() external view returns (uint256) {
    return _variableRateSlope1;
  }

  function variableRateSlope2() external view returns (uint256) {
    return _variableRateSlope2;
  }


  function baseVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate;
  }

  function getMaxVariableBorrowRate() external view override returns (uint256) {
    return _baseVariableBorrowRate.add(_variableRateSlope1).add(_variableRateSlope2);
  }

  struct CalcInterestRatesLocalVars {
    uint256 totalDebt;
    uint256 currentVariableBorrowRate;
    uint256 currentLiquidityRate;
    uint256 utilizationRate;
  }

  /**
   * @dev Calculates the interest rates depending on the reserve's state and configurations
   * @param availableLiquidity The liquidity available in the reserve
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param reserveFactor The reserve portion of the interest that goes to the treasury address.
   * @return The liquidity rate, the variable borrow rate
   **/
  function calculateInterestRates(
    uint256 availableLiquidity,
    uint256 totalVariableDebt,
    uint256 reserveFactor
  )
    external
    view
    override
    returns (
      uint256,
      uint256
    )
  {
    CalcInterestRatesLocalVars memory vars;
    vars.totalDebt = totalVariableDebt;
    vars.currentVariableBorrowRate = 0;
    vars.currentLiquidityRate = 0;

    uint256 utilizationRate =
      vars.totalDebt == 0 ? 0 : vars.totalDebt.rayDiv(availableLiquidity.add(vars.totalDebt));

    if (utilizationRate > OPTIMAL_UTILIZATION_RATE) {
      uint256 excessUtilizationRateRatio =
        utilizationRate.sub(OPTIMAL_UTILIZATION_RATE).rayDiv(EXCESS_UTILIZATION_RATE);


      vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(_variableRateSlope1).add(
        _variableRateSlope2.rayMul(excessUtilizationRateRatio)
      );
    } else {
      vars.currentVariableBorrowRate = _baseVariableBorrowRate.add(
        utilizationRate.rayMul(_variableRateSlope1).rayDiv(OPTIMAL_UTILIZATION_RATE)
      );
    }

    vars.currentLiquidityRate = _getOverallBorrowRate(
      totalVariableDebt,
      vars.currentVariableBorrowRate
    )
      .rayMul(utilizationRate)
      .percentMul(PercentageMath.PERCENTAGE_FACTOR.sub(reserveFactor));

    return (
      vars.currentLiquidityRate,
      vars.currentVariableBorrowRate
    );
  }

  /**
   * @dev Calculates the overall borrow rate as the weighted average between the total variable debt 
   * @param totalVariableDebt The total borrowed from the reserve at a variable rate
   * @param currentVariableBorrowRate The current variable borrow rate of the reserve
   * @return The weighted averaged borrow rate
   **/
  function _getOverallBorrowRate(
    uint256 totalVariableDebt,
    uint256 currentVariableBorrowRate
  ) internal pure returns (uint256) {

    if (totalVariableDebt == 0) return 0;

    uint256 weightedVariableRate = totalVariableDebt.wadToRay().rayMul(currentVariableBorrowRate);


    uint256 overallBorrowRate =
      weightedVariableRate.rayDiv(totalVariableDebt.wadToRay());

    return overallBorrowRate;
  }
}

