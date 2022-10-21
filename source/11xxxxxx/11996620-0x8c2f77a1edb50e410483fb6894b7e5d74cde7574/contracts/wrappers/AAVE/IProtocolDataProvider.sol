// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

interface IProtocolDataProvider {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }

  function getAllReservesTokens() external view returns (TokenData[] memory);
  function getAllATokens() external view returns (TokenData[] memory);
  function getReserveConfigurationData(address asset)
    external view returns(
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );
  function getReserveData(address asset)
    external view returns (
        uint256 availableLiquidity,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 stableBorrowRate,
        uint256 averageStableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint40 lastUpdateTimestamp
    );
  function getUserReserveData(address asset, address user)
    external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
  function getReserveTokensAddresses(address asset)
    external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
  function calculateUserGlobalData(address _user)
    external
    view
    returns (
        uint256 totalLiquidityBalanceETH,
        uint256 totalCollateralBalanceETH,
        uint256 totalBorrowBalanceETH,
        uint256 totalFeesETH,
        uint256 currentLtv,
        uint256 currentLiquidationThreshold,
        uint256 healthFactor,
        bool healthFactorBelowThreshold
    );
}

