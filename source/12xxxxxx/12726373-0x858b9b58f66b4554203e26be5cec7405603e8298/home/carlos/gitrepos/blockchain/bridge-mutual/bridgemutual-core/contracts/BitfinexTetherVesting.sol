// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";


contract BitfinexTetherVesting is Initializable, OwnableUpgradeable {
  using MathUpgradeable for uint256;
  using SafeMathUpgradeable for uint256;
  using SafeERC20 for IERC20;

  enum VestingSchedule {
    BITFINEX,
    TETHER
  }

  struct Vesting {
    bool isValid;
    address beneficiary;
    uint256 amount;
    VestingSchedule vestingSchedule;
    uint256 paidAmount;
    bool isCancelable;
  }

  struct LinearVestingSchedule {
    uint256 portionOfTotal;
    uint256 startDate;
    uint256 periodInSeconds;
    uint256 portionPerPeriod;
    uint256 cliffInPeriods;
  }

  uint256 public constant SECONDS_IN_MONTH = 60 * 60 * 24 * 30;
  uint256 public constant PORTION_OF_TOTAL_PRECISION = 10**10;
  uint256 public constant PORTION_PER_PERIOD_PRECISION = 10**10;

  IERC20 public token;
  Vesting[] public vestings;
  uint256 public amountInVestings;
  uint256 public tgeTimestamp;
  mapping(VestingSchedule => LinearVestingSchedule[]) public vestingSchedules;

  event TokenSet(IERC20 token);
  event VestingAdded(uint256 vestingId, address beneficiary);
  event VestingCanceled(uint256 vestingId);
  event VestingWithdraw(uint256 vestingId, uint256 amount);

  function initialize(uint256 _tgeTimestamp) public initializer {
    __Ownable_init();
    tgeTimestamp = _tgeTimestamp;

    initializeVestingSchedules();
  }
  function initializeVestingSchedules() internal {
    _addLinearVestingSchedule(
      VestingSchedule.BITFINEX,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH.mul(3),
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(4),
        cliffInPeriods: 0
      })
    );

    _addLinearVestingSchedule(
      VestingSchedule.TETHER,
      LinearVestingSchedule({
        portionOfTotal: PORTION_OF_TOTAL_PRECISION,
        startDate: tgeTimestamp,
        periodInSeconds: SECONDS_IN_MONTH.mul(3),
        portionPerPeriod: PORTION_PER_PERIOD_PRECISION.div(4),
        cliffInPeriods: 0
      })
    );
  }

  function updateTgeTimestamp(uint256 timestamp)
  public onlyOwner
  {
    delete vestingSchedules[VestingSchedule.BITFINEX];
    delete vestingSchedules[VestingSchedule.TETHER];
    tgeTimestamp = timestamp;
    initializeVestingSchedules();
  }

  function _addLinearVestingSchedule(VestingSchedule _type, LinearVestingSchedule memory _schedule) internal {
    vestingSchedules[_type].push(_schedule);
  }

  function setToken(IERC20 _token) external onlyOwner {
    require(address(token) == address(0), "token is already set");
    token = _token;
    emit TokenSet(token);
  }

  function createPartlyPaidVestingBulk(
    address[] calldata _beneficiary,
    uint256[] calldata _amount,
    VestingSchedule[] calldata _vestingSchedule,
    bool[] calldata _isCancelable,
    uint256[] calldata _paidAmount
  ) external onlyOwner {
    require(
      _beneficiary.length == _amount.length &&
        _beneficiary.length == _vestingSchedule.length &&
        _beneficiary.length == _isCancelable.length &&
        _beneficiary.length == _paidAmount.length,
      "Parameters length mismatch"
    );

    for (uint256 i = 0; i < _beneficiary.length; i++) {
      _createVesting(_beneficiary[i], _amount[i], _vestingSchedule[i], _isCancelable[i], _paidAmount[i]);
    }
  }

  function createVesting(
    address _beneficiary,
    uint256 _amount,
    VestingSchedule _vestingSchedule,
    bool _isCancelable
  ) external onlyOwner returns (uint256 vestingId) {
    return _createVesting(_beneficiary, _amount, _vestingSchedule, _isCancelable, 0);
  }

  function _createVesting(
    address _beneficiary,
    uint256 _amount,
    VestingSchedule _vestingSchedule,
    bool _isCancelable,
    uint256 _paidAmount
  ) internal returns (uint256 vestingId) {
    require(_beneficiary != address(0), "Cannot create vesting for zero address");

    uint256 amountToVest = _amount.sub(_paidAmount);
    require(getTokensAvailable() >= amountToVest, "Not enough tokens");
    amountInVestings = amountInVestings.add(amountToVest);

    vestingId = vestings.length;
    vestings.push(
      Vesting({
        isValid: true,
        beneficiary: _beneficiary,
        amount: _amount,
        vestingSchedule: _vestingSchedule,
        paidAmount: _paidAmount,
        isCancelable: _isCancelable
      })
    );

    emit VestingAdded(vestingId, _beneficiary);
  }

  function cancelVesting(uint256 _vestingId) external onlyOwner {
    Vesting storage vesting = getVesting(_vestingId);
    require(vesting.isCancelable, "Vesting is not cancelable");

    _forceCancelVesting(_vestingId, vesting);
  }

  function _forceCancelVesting(uint256 _vestingId, Vesting storage _vesting) internal {
    require(_vesting.isValid, "Vesting is canceled");
    _vesting.isValid = false;
    uint256 amountReleased = _vesting.amount.sub(_vesting.paidAmount);
    amountInVestings = amountInVestings.sub(amountReleased);

    emit VestingCanceled(_vestingId);
  }

  function withdrawFromVestingBulk(uint256 _offset, uint256 _limit) external {
    uint256 to = (_offset + _limit).min(vestings.length).max(_offset);
    for (uint256 i = _offset; i < to; i++) {
      Vesting storage vesting = getVesting(i);
      if (vesting.isValid) {
        _withdrawFromVesting(vesting, i);
      }
    }
  }

  function withdrawFromVesting(uint256 _vestingId) external {
    Vesting storage vesting = getVesting(_vestingId);
    require(vesting.isValid, "Vesting is canceled");

    _withdrawFromVesting(vesting, _vestingId);
  }

  function _withdrawFromVesting(Vesting storage _vesting, uint256 _vestingId) internal {
    uint256 amountToPay = _getWithdrawableAmount(_vesting);
    if (amountToPay == 0) return;
    _vesting.paidAmount = _vesting.paidAmount.add(amountToPay);
    amountInVestings = amountInVestings.sub(amountToPay);
    token.transfer(_vesting.beneficiary, amountToPay);

    emit VestingWithdraw(_vestingId, amountToPay);
  }

  function getWithdrawableAmount(uint256 _vestingId) external view returns (uint256) {
    Vesting storage vesting = getVesting(_vestingId);
    require(vesting.isValid, "Vesting is canceled");

    return _getWithdrawableAmount(vesting);
  }

  function _getWithdrawableAmount(Vesting storage _vesting) internal view returns (uint256) {
    return calculateAvailableAmount(_vesting).sub(_vesting.paidAmount);
  }

  function calculateAvailableAmount(Vesting storage _vesting) internal view returns (uint256) {
    LinearVestingSchedule[] memory vestingSchedule = vestingSchedules[_vesting.vestingSchedule];
    uint256 amountAvailable = 0;
    for (uint256 i = 0; i < vestingSchedule.length; i++) {
      LinearVestingSchedule memory linearSchedule = vestingSchedule[i];
      if (linearSchedule.startDate > block.timestamp) return amountAvailable;
      uint256 amountThisLinearSchedule = calculateLinearVestingAvailableAmount(linearSchedule, _vesting.amount);
      amountAvailable = amountAvailable.add(amountThisLinearSchedule);
    }
    return amountAvailable;
  }

  function calculateLinearVestingAvailableAmount(LinearVestingSchedule memory _linearVesting, uint256 _amount)
    internal
    view
    returns (uint256)
  {
    uint256 elapsedPeriods = calculateElapsedPeriods(_linearVesting);
    if (elapsedPeriods <= _linearVesting.cliffInPeriods) return 0;
    uint256 amountThisVestingSchedule = _amount.mul(_linearVesting.portionOfTotal).div(PORTION_OF_TOTAL_PRECISION);
    uint256 amountPerPeriod =
      amountThisVestingSchedule.mul(_linearVesting.portionPerPeriod).div(PORTION_PER_PERIOD_PRECISION);
    return amountPerPeriod.mul(elapsedPeriods).min(amountThisVestingSchedule);
  }

  function calculateElapsedPeriods(LinearVestingSchedule memory _linearVesting) private view returns (uint256) {
    return block.timestamp.sub(_linearVesting.startDate).div(_linearVesting.periodInSeconds);
  }

  function getVesting(uint256 _vestingId) internal view returns (Vesting storage) {
    require(_vestingId < vestings.length, "No vesting with such id");
    return vestings[_vestingId];
  }

  function withdrawExcessiveTokens() external onlyOwner {
    token.transfer(owner(), getTokensAvailable());
  }

  function getTokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this)).sub(amountInVestings);
  }

  function getVestingById(uint256 _vestingId)
    public
    view
    returns (
      bool isValid,
      address beneficiary,
      uint256 amount,
      VestingSchedule vestingSchedule,
      uint256 paidAmount,
      bool isCancelable
    )
  {
    Vesting storage vesting = getVesting(_vestingId);
    isValid = vesting.isValid;
    beneficiary = vesting.beneficiary;
    amount = vesting.amount;
    vestingSchedule = vesting.vestingSchedule;
    paidAmount = vesting.paidAmount;
    isCancelable = vesting.isCancelable;
  }

  function getVestingsCount() public view returns (uint256 _vestingsCount) {
    return vestings.length;
  }
}

