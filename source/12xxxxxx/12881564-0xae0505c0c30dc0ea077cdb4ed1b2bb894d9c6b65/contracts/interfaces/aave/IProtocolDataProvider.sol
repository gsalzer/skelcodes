pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface IProtocolDataProvider {
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
}

