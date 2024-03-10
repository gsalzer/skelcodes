// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// Uniswap Adapter
import {BaseUniswapAdapter} from '@aave/protocol-v2/contracts/adapters/BaseUniswapAdapter.sol';

// Interfaces
import {
  ILendingPoolAddressesProvider
} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '@aave/protocol-v2/contracts/interfaces/ILendingPool.sol';
import {IUniswapV2Router02} from '@aave/protocol-v2/contracts/interfaces/IUniswapV2Router02.sol';
import {IERC20} from '@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/IERC20.sol';
import {
  SafeERC20
} from '@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/SafeERC20.sol';

/**
 * @title FlashLiquidationAdapter
 * @notice Flash Liquidation that uses Uniswap V2 Adapter to swap released collateral during Aave V2 liquidations.
 * @dev You can check latest source at Aave Protocol V2 repository: https://github.com/aave/protocol-v2/blob/master/contracts/adapters/FlashLiquidationAdapter.sol
 * @author Aave
 **/
contract FlashLiquidationAdapter is BaseUniswapAdapter {
  using SafeERC20 for IERC20;

  struct LiquidationParams {
    address collateralAsset;
    address borrowedAsset;
    address user;
    uint256 debtToCover;
    bool useEthPath;
  }

  struct LiquidationCallLocalVars {
    uint256 initFlashBorrowedBalance;
    uint256 diffFlashBorrowedBalance;
    uint256 initCollateralBalance;
    uint256 diffCollateralBalance;
    uint256 flashLoanDebt;
    uint256 soldAmount;
    uint256 remainingTokens;
    uint256 borrowedAssetLeftovers;
  }

  constructor(
    ILendingPoolAddressesProvider addressesProvider,
    IUniswapV2Router02 uniswapRouter,
    address wethAddress
  ) public BaseUniswapAdapter(addressesProvider, uniswapRouter, wethAddress) {}

  /**
   * @dev Liquidate a non-healthy position collateral-wise, with a Health Factor below 1, using Flash Loan and Uniswap to repay flash loan premium.
   * - The caller (liquidator) with a flash loan covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk minus the flash loan premium.
   * @param assets Address of asset to be swapped
   * @param amounts Amount of the asset to be swapped
   * @param premiums Fee of the flash loan
   * @param initiator Address of the caller
   * @param params Additional variadic field to include extra params. Expected parameters:
   *   address collateralAsset The collateral asset to release and will be exchanged to pay the flash loan premium
   *   address borrowedAsset The asset that must be covered
   *   address user The user address with a Health Factor below 1
   *   uint256 debtToCover The amount of debt to cover
   *   bool useEthPath Use WETH as connector path between the collateralAsset and borrowedAsset at Uniswap
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external override returns (bool) {
    require(msg.sender == address(LENDING_POOL), 'CALLER_MUST_BE_LENDING_POOL');

    LiquidationParams memory decodedParams = _decodeParams(params);

    require(assets.length == 1 && assets[0] == decodedParams.borrowedAsset, 'INCONSISTENT_PARAMS');

    _liquidateAndSwap(
      decodedParams.collateralAsset,
      decodedParams.borrowedAsset,
      decodedParams.user,
      decodedParams.debtToCover,
      decodedParams.useEthPath,
      amounts[0],
      premiums[0],
      initiator
    );

    return true;
  }

  /**
   * @dev
   * @param collateralAsset The collateral asset to release and will be exchanged to pay the flash loan premium
   * @param borrowedAsset The asset that must be covered
   * @param user The user address with a Health Factor below 1
   * @param debtToCover The amount of debt to coverage, can be max(-1) to liquidate all possible debt
   * @param useEthPath true if the swap needs to occur using ETH in the routing, false otherwise
   * @param flashBorrowedAmount Amount of asset requested at the flash loan to liquidate the user position
   * @param premium Fee of the requested flash loan
   * @param initiator Address of the caller
   */
  function _liquidateAndSwap(
    address collateralAsset,
    address borrowedAsset,
    address user,
    uint256 debtToCover,
    bool useEthPath,
    uint256 flashBorrowedAmount,
    uint256 premium,
    address initiator
  ) internal {
    LiquidationCallLocalVars memory vars;
    vars.initCollateralBalance = IERC20(collateralAsset).balanceOf(address(this));
    if (collateralAsset != borrowedAsset) {
      vars.initFlashBorrowedBalance = IERC20(borrowedAsset).balanceOf(address(this));

      // Track leftover balance to rescue funds in case of external transfers into this contract
      vars.borrowedAssetLeftovers = vars.initFlashBorrowedBalance.sub(flashBorrowedAmount);
    }
    vars.flashLoanDebt = flashBorrowedAmount.add(premium);

    // Approve LendingPool to use debt token for liquidation
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), 0);
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), debtToCover);

    // Liquidate the user position and release the underlying collateral
    LENDING_POOL.liquidationCall(collateralAsset, borrowedAsset, user, debtToCover, false);

    // Discover the liquidated tokens
    uint256 collateralBalanceAfter = IERC20(collateralAsset).balanceOf(address(this));

    // Track only collateral released, not current asset balance of the contract
    vars.diffCollateralBalance = collateralBalanceAfter.sub(vars.initCollateralBalance);

    if (collateralAsset != borrowedAsset) {
      // Discover flash loan balance after the liquidation
      uint256 flashBorrowedAssetAfter = IERC20(borrowedAsset).balanceOf(address(this));

      // Use only flash loan borrowed assets, not current asset balance of the contract
      vars.diffFlashBorrowedBalance = flashBorrowedAssetAfter.sub(vars.borrowedAssetLeftovers);

      // Swap released collateral into the debt asset, to repay the flash loan
      vars.soldAmount = _swapTokensForExactTokens(
        collateralAsset,
        borrowedAsset,
        vars.diffCollateralBalance,
        vars.flashLoanDebt.sub(vars.diffFlashBorrowedBalance),
        useEthPath
      );
      vars.remainingTokens = vars.diffCollateralBalance.sub(vars.soldAmount);
    } else {
      vars.remainingTokens = vars.diffCollateralBalance.sub(premium);
    }

    // Allow repay of flash loan
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), 0);
    IERC20(borrowedAsset).safeApprove(address(LENDING_POOL), vars.flashLoanDebt);

    // Transfer remaining tokens to initiator
    if (vars.remainingTokens > 0) {
      IERC20(collateralAsset).safeTransfer(initiator, vars.remainingTokens);
    }
  }

  /**
   * @dev Decodes the information encoded in the flash loan params
   * @param params Additional variadic field to include extra params. Expected parameters:
   *   address collateralAsset The collateral asset to claim
   *   address borrowedAsset The asset that must be covered and will be exchanged to pay the flash loan premium
   *   address user The user address with a Health Factor below 1
   *   uint256 debtToCover The amount of debt to cover
   *   bool useEthPath Use WETH as connector path between the collateralAsset and borrowedAsset at Uniswap
   * @return LiquidationParams struct containing decoded params
   */
  function _decodeParams(bytes memory params) internal pure returns (LiquidationParams memory) {
    (
      address collateralAsset,
      address borrowedAsset,
      address user,
      uint256 debtToCover,
      bool useEthPath
    ) = abi.decode(params, (address, address, address, uint256, bool));

    return LiquidationParams(collateralAsset, borrowedAsset, user, debtToCover, useEthPath);
  }

  function requestFlashLoan(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata modes,
    bytes calldata params
  ) external {
    // Request a Flash Loan to Lending Pool
    ILendingPool(LENDING_POOL).flashLoan(
      address(this),
      assets,
      amounts,
      modes,
      address(this),
      params,
      0
    );

    LiquidationParams memory decodedParams = _decodeParams(params);

    // Transfer the remaining collateral to the msg.sender
    uint256 allBalance = IERC20(decodedParams.collateralAsset).balanceOf(address(this));
    IERC20(decodedParams.collateralAsset).safeTransfer(msg.sender, allBalance);
  }
}

