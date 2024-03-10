// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import '../../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../../../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../common/implementation/Lockable.sol';
import '../../common/implementation/FixedPoint.sol';
import './FeePayerPoolPartyLib.sol';
import '../../common/implementation/Testable.sol';

import '../../oracle/interfaces/StoreInterface.sol';
import '../../oracle/interfaces/FinderInterface.sol';
import '../../oracle/interfaces/AdministrateeInterface.sol';
import '../../oracle/implementation/Constants.sol';

abstract contract FeePayerPoolParty is
  AdministrateeInterface,
  Testable,
  Lockable
{
  using SafeMath for uint256;
  using FixedPoint for FixedPoint.Unsigned;
  using FeePayerPoolPartyLib for FixedPoint.Unsigned;
  using FeePayerPoolPartyLib for FeePayerData;
  using SafeERC20 for IERC20;

  struct FeePayerData {
    IERC20 collateralCurrency;
    FinderInterface finder;
    uint256 lastPaymentTime;
    FixedPoint.Unsigned cumulativeFeeMultiplier;
  }

  FeePayerData public feePayerData;

  event RegularFeesPaid(uint256 indexed regularFee, uint256 indexed lateFee);
  event FinalFeesPaid(uint256 indexed amount);

  modifier fees {
    payRegularFees();
    _;
  }
  modifier onlyThisContract {
    require(msg.sender == address(this), 'Caller is not this contract');
    _;
  }

  constructor(
    address _collateralAddress,
    address _finderAddress,
    address _timerAddress
  ) public Testable(_timerAddress) {
    feePayerData.collateralCurrency = IERC20(_collateralAddress);
    feePayerData.finder = FinderInterface(_finderAddress);
    feePayerData.lastPaymentTime = getCurrentTime();
    feePayerData.cumulativeFeeMultiplier = FixedPoint.fromUnscaledUint(1);
  }

  function payRegularFees()
    public
    nonReentrant()
    returns (FixedPoint.Unsigned memory totalPaid)
  {
    StoreInterface store = _getStore();
    uint256 time = getCurrentTime();
    FixedPoint.Unsigned memory collateralPool = _pfc();
    totalPaid = feePayerData.payRegularFees(store, time, collateralPool);
    return totalPaid;
  }

  function payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    external
    onlyThisContract
  {
    _payFinalFees(payer, amount);
  }

  function pfc()
    public
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory)
  {
    return _pfc();
  }

  function collateralCurrency()
    public
    view
    nonReentrantView()
    returns (IERC20)
  {
    return feePayerData.collateralCurrency;
  }

  function _payFinalFees(address payer, FixedPoint.Unsigned memory amount)
    internal
  {
    StoreInterface store = _getStore();
    feePayerData.payFinalFees(store, payer, amount);
  }

  function _pfc() internal view virtual returns (FixedPoint.Unsigned memory);

  function _getStore() internal view returns (StoreInterface) {
    return
      StoreInterface(
        feePayerData.finder.getImplementationAddress(OracleInterfaces.Store)
      );
  }

  function _computeFinalFees()
    internal
    view
    returns (FixedPoint.Unsigned memory finalFees)
  {
    StoreInterface store = _getStore();
    return store.computeFinalFee(address(feePayerData.collateralCurrency));
  }
}

