// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.6.12;

interface IProposalGenericExecutor {
  function execute(
    address token,
    address aToken,
    address stableDebtToken,
    address variablDebtToken,
    address interestStrategy,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    uint256 reserveFactor,
    uint8 decimals,
    bool enableBorrow,
    bool enableBorrowOnReserve,
    bool enableAsCollateral
  ) external;
}
