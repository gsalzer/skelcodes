// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "../interfaces/CompoundInterfaces.sol";
import "./LowGasSafeMath.sol";
import "./MinimalSignedMath.sol";


library CTokenParams {
  using LowGasSafeMath for uint256;
  using MinimalSignedMath for uint256;

  uint256 internal constant EXP_SCALE = 1e18;
  uint256 internal constant HALF_EXP_SCALE = 5e17;

  function getInterestRateParameters(address token) internal view returns (
    address model,
    uint256 cashPrior,
    uint256 borrowsPrior,
    uint256 reservesPrior,
    uint256 reserveFactorMantissa
  ) {
    ICToken cToken = ICToken(token);
    model = address(cToken.interestRateModel());

    cashPrior = cToken.getCash();
    borrowsPrior = cToken.totalBorrows();
    reservesPrior = cToken.totalReserves();
    uint256 accrualBlockNumber = cToken.accrualBlockNumber();
    uint256 blockDelta = block.number - accrualBlockNumber;
    reserveFactorMantissa = cToken.reserveFactorMantissa();
    if (blockDelta > 0) {
      uint256 borrowRateMantissa = getBorrowRate(address(model), cashPrior, borrowsPrior, reservesPrior);
      uint256 interestAccumulated = mulScalarTruncate(borrowRateMantissa.mul(blockDelta), borrowsPrior);
      borrowsPrior = borrowsPrior.add(interestAccumulated);
      reservesPrior = mulScalarTruncate(reserveFactorMantissa, interestAccumulated).add(reservesPrior);
    }
  }

  function currentExchangeRate(address token) internal view returns (uint256 exchangeRate) {
    ICToken cToken = ICToken(token);
    uint256 blockDelta = block.number - cToken.accrualBlockNumber();
    if (blockDelta == 0) {
      return cToken.exchangeRateStored();
    }

    IInterestRateModel model = cToken.interestRateModel();

    uint256 cashPrior = cToken.getCash();
    uint256 borrowsPrior = cToken.totalBorrows();
    uint256 reservesPrior = cToken.totalReserves();
    uint256 reserveFactorMantissa = cToken.reserveFactorMantissa();
    if (blockDelta > 0) {
      uint256 borrowRateMantissa = getBorrowRate(address(model), cashPrior, borrowsPrior, reservesPrior);
      uint256 interestAccumulated = mulScalarTruncate(borrowRateMantissa.mul(blockDelta), borrowsPrior);
      borrowsPrior = borrowsPrior.add(interestAccumulated);
      reservesPrior = mulScalarTruncate(reserveFactorMantissa, interestAccumulated).add(reservesPrior);
    }

    return cashPrior.add(borrowsPrior).sub(reservesPrior).mul(1e18) / ICToken(token).totalSupply();
  }
  

  function truncate(uint256 x) internal pure returns (uint256) {
    return x / EXP_SCALE;
  }

  function mulScalarTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
    return truncate(x.mul(y));
  }

  function mulScalarTruncateAddUInt(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
    return mulScalarTruncate(x, y).add(z);
  }

  function getBorrowRate(
    address model,
    uint256 cash,
    uint256 borrows,
    uint256 reserves
  ) internal view returns (uint256 borrowRateMantissa) {
    (bool success, bytes memory retData) = model.staticcall(
      abi.encodeWithSelector(
        IInterestRateModel.getBorrowRate.selector,
        cash,
        borrows,
        reserves
      )
    );
    if (!success) revert(abi.decode(retData, (string)));
    assembly {
      switch lt(mload(retData), 64)
      case 0 {borrowRateMantissa := mload(add(retData, 64))}
      default {borrowRateMantissa := mload(add(retData, 32))}
    }
  }
}
