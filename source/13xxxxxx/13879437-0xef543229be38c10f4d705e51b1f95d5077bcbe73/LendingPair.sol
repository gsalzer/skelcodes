// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

pragma solidity 0.8.6;

import "IERC20.sol";
import "IERC721.sol";
import "ILPTokenMaster.sol";
import "ILendingPair.sol";
import "ILendingController.sol";
import "IInterestRateModel.sol";
import "IUniswapV3Helper.sol";
import "INonfungiblePositionManagerSimple.sol";

import "Math.sol";
import "Clones.sol";
import "ReentrancyGuard.sol";
import "AddressLibrary.sol";

import "LPTokenMaster.sol";

import "ERC721Receivable.sol";
import "TransferHelper.sol";

contract LendingPair is ILendingPair, ReentrancyGuard, TransferHelper, ERC721Receivable {

  INonfungiblePositionManagerSimple internal constant positionManager = INonfungiblePositionManagerSimple(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  IERC721 internal constant uniPositions = IERC721(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
  uint    public   constant LIQ_MIN_HEALTH = 1e18;
  uint    private  constant MIN_DECIMALS = 6;

  using AddressLibrary for address;
  using Clones for address;

  mapping (address => mapping (address => uint)) public override supplySharesOf;
  mapping (address => mapping (address => uint)) public debtSharesOf;
  mapping (address => uint) public override pendingSystemFees;
  mapping (address => uint) public lastBlockAccrued;
  mapping (address => uint) public override totalSupplyShares;
  mapping (address => uint) public override totalSupplyAmount;
  mapping (address => uint) public override totalDebtShares;
  mapping (address => uint) public override totalDebtAmount;
  mapping (address => uint) public uniPosition;
  mapping (address => uint) private decimals;
  mapping (address => address) public override lpToken;

  IUniswapV3Helper   private uniV3Helper;
  ILendingController public  lendingController;

  address public feeRecipient;
  address public override tokenA;
  address public override tokenB;

  event Liquidation(
    address indexed account,
    address indexed repayToken,
    address indexed supplyToken,
    uint repayAmount,
    uint supplyAmount
  );

  event Deposit(address indexed account, address indexed token, uint amount);
  event Withdraw(address indexed account, address indexed token, uint amount);
  event Borrow(address indexed account, address indexed token, uint amount);
  event Repay(address indexed account, address indexed token, uint amount);
  event CollectSystemFee(address indexed token, uint amount);
  event DepositUniPosition(address indexed account, uint positionID);
  event WithdrawUniPosition(address indexed account, uint positionID);

  modifier onlyLpToken() {
    require(lpToken[tokenA] == msg.sender || lpToken[tokenB] == msg.sender, "LendingController: caller must be LP token");
    _;
  }

  function initialize(
    address _lpTokenMaster,
    address _lendingController,
    address _uniV3Helper,
    address _feeRecipient,
    address _tokenA,
    address _tokenB
  ) external override {
    require(tokenA == address(0), "LendingPair: already initialized");

    lendingController = ILendingController(_lendingController);
    uniV3Helper       = IUniswapV3Helper(_uniV3Helper);
    feeRecipient      = _feeRecipient;
    tokenA = _tokenA;
    tokenB = _tokenB;
    lastBlockAccrued[tokenA] = block.number;
    lastBlockAccrued[tokenB] = block.number;

    decimals[tokenA] = IERC20(tokenA).decimals();
    decimals[tokenB] = IERC20(tokenB).decimals();

    require(decimals[tokenA] >= MIN_DECIMALS && decimals[tokenB] >= MIN_DECIMALS, "LendingPair: MIN_DECIMALS");

    lpToken[tokenA] = _createLpToken(_lpTokenMaster, tokenA);
    lpToken[tokenB] = _createLpToken(_lpTokenMaster, tokenB);
  }

  // Deposit limits do not apply to Uniswap positions
  function depositUniPosition(address _account, uint _positionID) external nonReentrant {
    _checkDepositsEnabled();
    _validateUniPosition(_positionID);
    require(_positionID > 0, "LendingPair: invalid position");
    require(uniPosition[_account] == 0, "LendingPair: one position per account");

    uniPositions.safeTransferFrom(msg.sender, address(this), _positionID);
    uniPosition[_account] = _positionID;

    emit DepositUniPosition(_account, _positionID);
  }

  function withdrawUniPosition() external nonReentrant {
    uint positionID = uniPosition[msg.sender];
    require(positionID > 0, "LendingPair: nothing to withdraw");
    uniPositions.safeTransferFrom(address(this), msg.sender, positionID);
    uniPosition[msg.sender] = 0;

    accrue(tokenA);
    accrue(tokenB);
    checkAccountHealth(msg.sender);

    emit WithdrawUniPosition(msg.sender, positionID);
  }

  // claim & mint supply from uniswap fees
  function uniClaimDeposit() external nonReentrant {
    accrue(tokenA);
    accrue(tokenB);
    (uint amountA, uint amountB) = _uniCollectFees(msg.sender);
    _mintSupplyAmount(tokenA, msg.sender, amountA);
    _mintSupplyAmount(tokenB, msg.sender, amountB);
  }

  // claim & withdraw uniswap fees
  function uniClaimWithdraw() external nonReentrant {
    (uint amountA, uint amountB) = _uniCollectFees(msg.sender);
    _safeTransfer(tokenA, msg.sender, amountA);
    _safeTransfer(tokenB, msg.sender, amountB);
    _checkReserve(tokenA);
    _checkReserve(tokenB);
  }

  function depositRepay(address _account, address _token, uint _amount) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _depositRepay(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function depositRepayETH(address _account) external payable nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    _depositRepay(_account, address(WETH), msg.value);
    _depositWeth();
  }

  function deposit(address _account, address _token, uint _amount) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _deposit(_account, _token, _amount);
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function withdrawBorrow(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _withdrawBorrow(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
    _checkReserve(_token);
  }

  function withdrawBorrowETH(uint _amount) external nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    _withdrawBorrow(address(WETH), _amount);
    _wethWithdrawTo(msg.sender, _amount);
    _checkReserve(address(WETH));
  }

  function withdraw(address _token, uint _amount) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _withdrawShares(_token, _supplyToShares(_token, _amount));
    _safeTransfer(_token, msg.sender, _amount);
    _checkReserve(_token);
  }

  function withdrawAll(address _token) external override nonReentrant {
    _validateToken(_token);
    accrue(_token);

    uint shares = supplySharesOf[_token][msg.sender];
    uint amount = _sharesToSupply(_token, shares);
    _withdrawShares(_token, shares);
    _safeTransfer(_token, msg.sender, amount);
    _checkReserve(_token);
  }

  function withdrawAllETH() external nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    uint shares = supplySharesOf[address(WETH)][msg.sender];
    uint amount = _sharesToSupply(address(WETH), shares);
    _withdrawShares(address(WETH), shares);
    _wethWithdrawTo(msg.sender, amount);
    _checkReserve(address(WETH));
  }

  function borrow(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _borrow(_token, _amount);
    _safeTransfer(_token, msg.sender, _amount);
    _checkReserve(_token);
  }

  function repayAll(address _account, address _token, uint _maxAmount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    uint amount = _repayShares(_account, _token, debtSharesOf[_token][_account]);
    require(amount <= _maxAmount, "LendingPair: amount <= _maxAmount");
    _safeTransferFrom(_token, msg.sender, amount);
  }

  function repayAllETH(address _account) external payable nonReentrant {
    _validateToken(address(WETH));
    accrue(address(WETH));

    uint amount = _repayShares(_account, address(WETH), debtSharesOf[address(WETH)][_account]);
    require(msg.value >= amount, "LendingPair: insufficient ETH deposit");

    _depositWeth();
    uint refundAmount = msg.value > amount ? (msg.value - amount) : 0;

    if (refundAmount > 0) {
      _wethWithdrawTo(msg.sender, refundAmount);
    }
  }

  function repay(address _account, address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    accrue(_token);

    _repayShares(_account, _token, _debtToShares(_token, _amount));
    _safeTransferFrom(_token, msg.sender, _amount);
  }

  function accrue(address _token) public {
    if (lastBlockAccrued[_token] < block.number) {
      uint newDebt   = _accrueDebt(_token);
      uint newSupply = newDebt * _lpRate(_token) / 100e18;
      totalSupplyAmount[_token] += newSupply;

      // '-1' helps prevent _checkReserve fails due to rounding errors
      uint newFees = (newDebt - newSupply) == 0 ? 0 : (newDebt - newSupply - 1);
      pendingSystemFees[_token] += newFees;

      lastBlockAccrued[_token]   = block.number;
    }
  }

  function collectSystemFee(address _token, uint _amount) external nonReentrant {
    _validateToken(_token);
    pendingSystemFees[_token] -= _amount;
    _safeTransfer(_token, feeRecipient, _amount);
    _checkReserve(_token);
    emit CollectSystemFee(_token, _amount);
  }

  function transferLp(address _token, address _from, address _to, uint _amount) external override onlyLpToken {
    require(debtSharesOf[_token][_to] == 0, "LendingPair: cannot receive borrowed token");
    supplySharesOf[_token][_from] -= _amount;
    supplySharesOf[_token][_to]   += _amount;
    checkAccountHealth(_from);
  }

  // Sell collateral to reduce debt and increase accountHealth
  // Set _repayAmount to type(uint).max to repay all debt, inc. pending interest
  function liquidateAccount(
    address _account,
    address _repayToken,
    uint    _repayAmount,
    uint    _minSupplyOutput
  ) external nonReentrant {

    // Input validation and adjustments

    _validateToken(_repayToken);

    address supplyToken = _repayToken == tokenA ? tokenB : tokenA;

    // Check account is underwater after interest

    accrue(supplyToken);
    accrue(_repayToken);

    uint health = accountHealth(_account);
    require(health < LIQ_MIN_HEALTH, "LendingPair: account health < LIQ_MIN_HEALTH");

    // Fully unwrap Uni position - withdraw & mint supply

    _unwrapUniPosition(_account);

    // Calculate balance adjustments

    _repayAmount = Math.min(_repayAmount, _debtOf(_repayToken, _account));
    (uint repayPrice, uint supplyPrice) = lendingController.tokenPrices(_repayToken, supplyToken);

    uint supplyDebt   = _convertTokenValues(_repayToken, supplyToken, _repayAmount, repayPrice, supplyPrice);
    uint callerFee    = supplyDebt * lendingController.liqFeeCaller(_repayToken) / 100e18;
    uint systemFee    = supplyDebt * lendingController.liqFeeSystem(_repayToken) / 100e18;
    uint supplyBurn   = supplyDebt + callerFee + systemFee;
    uint supplyOutput = supplyDebt + callerFee;

    require(supplyOutput >= _minSupplyOutput, "LendingPair: supplyOutput >= _minSupplyOutput");

    // Adjust balances

    _burnSupplyShares(supplyToken, _account, _supplyToShares(supplyToken, supplyBurn));
    pendingSystemFees[supplyToken] += systemFee;
    _burnDebtShares(_repayToken, _account, _debtToShares(_repayToken, _repayAmount));

    // Uni position unwrapping can mint supply of already borrowed tokens

    _repayDebtFromSupply(_account, tokenA);
    _repayDebtFromSupply(_account, tokenB);

    // Settle token transfers

    _safeTransferFrom(_repayToken, msg.sender, _repayAmount);
    _mintSupplyAmount(supplyToken, msg.sender, supplyOutput);

    _checkReserve(tokenA);
    _checkReserve(tokenB);

    emit Liquidation(_account, _repayToken, supplyToken, _repayAmount, supplyOutput);
  }

  // Compare all supply & borrow balances converted into the the same token - tokenA
  function accountHealth(address _account) public view returns(uint) {

    if (debtSharesOf[tokenA][_account] == 0 && debtSharesOf[tokenB][_account] == 0) {
      return LIQ_MIN_HEALTH;
    }

    (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);
    uint colFactorA = lendingController.colFactor(tokenA);
    uint colFactorB = lendingController.colFactor(tokenB);

    uint creditA   = _supplyOf(tokenA, _account) * colFactorA / 100e18;
    uint creditB   = _supplyBalanceConverted(_account, tokenB, tokenA, priceB, priceA) * colFactorB / 100e18;
    uint creditUni = _convertedCreditAUni(_account, priceA, priceB, colFactorA, colFactorB);

    uint totalAccountSupply = creditA + creditB + creditUni;

    uint totalAccountBorrow = _debtOf(tokenA, _account) + _borrowBalanceConverted(_account, tokenB, tokenA, priceB, priceA);

    return totalAccountSupply * 1e18 / totalAccountBorrow;
  }

  function debtOf(address _token, address _account) external view returns(uint) {
    _validateToken(_token);
    return _debtOf(_token, _account);
  }

  function supplyOf(address _token, address _account) external view override returns(uint) {
    _validateToken(_token);
    return _supplyOf(_token, _account);
  }

  // Get borow balance converted to the units of _returnToken
  function borrowBalanceConverted(
    address _account,
    address _borrowedToken,
    address _returnToken
  ) external view returns(uint) {

    _validateToken(_borrowedToken);
    _validateToken(_returnToken);

    (uint borrowPrice, uint returnPrice) = lendingController.tokenPrices(_borrowedToken, _returnToken);
    return _borrowBalanceConverted(_account, _borrowedToken, _returnToken, borrowPrice, returnPrice);
  }

  function supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken
  ) external view override returns(uint) {

    _validateToken(_suppliedToken);
    _validateToken(_returnToken);

    (uint supplyPrice, uint returnPrice) = lendingController.tokenPrices(_suppliedToken, _returnToken);
    return _supplyBalanceConverted(_account, _suppliedToken, _returnToken, supplyPrice, returnPrice);
  }

  function supplyRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    if (totalSupplyAmount[_token] == 0 || totalDebtAmount[_token] == 0) { return 0; }
    uint utilizationRate = totalDebtAmount[_token] * 100e18 / totalSupplyAmount[_token];
    return _interestRatePerBlock(_token) * utilizationRate * _lpRate(_token) / 100e18 / 100e18;
  }

  function borrowRatePerBlock(address _token) external view returns(uint) {
    _validateToken(_token);
    return _interestRatePerBlock(_token);
  }

  function checkAccountHealth(address _account) public view  {
    uint health = accountHealth(_account);
    require(health >= LIQ_MIN_HEALTH, "LendingPair: insufficient accountHealth");
  }

  function convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount
  ) external view returns(uint) {

    _validateToken(_fromToken);
    _validateToken(_toToken);

    (uint fromPrice, uint toPrice) = lendingController.tokenPrices(_fromToken, _toToken);
    return _convertTokenValues(_fromToken, _toToken, _inputAmount, fromPrice, toPrice);
  }

  function _depositRepay(address _account, address _token, uint _amount) internal {

    uint debt          = _debtOf(_token, _account);
    uint repayAmount   = debt > _amount ? _amount : debt;
    uint depositAmount = _amount - repayAmount;

    if (repayAmount > 0) {
      _repayShares(_account, _token, _debtToShares(_token, repayAmount));
    }

    if (depositAmount > 0) {
      _deposit(_account, _token, depositAmount);
    }
  }

  function _withdrawBorrow(address _token, uint _amount) internal {

    uint supplyAmount   = _supplyOf(_token, msg.sender);
    uint withdrawAmount = supplyAmount > _amount ? _amount : supplyAmount;
    uint borrowAmount   = _amount - withdrawAmount;

    if (withdrawAmount > 0) {
      _withdrawShares(_token, _supplyToShares(_token, withdrawAmount));
    }

    if (borrowAmount > 0) {
      _borrow(_token, borrowAmount);
    }
  }

  // Uses price oracle to estimate min outputs to reduce MEV
  // Liquidation might be temporarily unavailable due to this
  function _unwrapUniPosition(address _account) internal {

    if (uniPosition[_account] > 0) {

      (uint priceA, uint priceB) = lendingController.tokenPrices(tokenA, tokenB);
      (uint amount0, uint amount1) = _positionAmounts(uniPosition[_account], priceA, priceB);
      uint uniMinOutput = lendingController.uniMinOutputPct();

      uniPositions.approve(address(uniV3Helper), uniPosition[_account]);
      (uint amountA, uint amountB) = uniV3Helper.removeLiquidity(
        uniPosition[_account],
        amount0 * uniMinOutput / 100e18,
        amount1 * uniMinOutput / 100e18
      );
      uniPosition[_account] = 0;

      _mintSupplyAmount(tokenA, _account, amountA);
      _mintSupplyAmount(tokenB, _account, amountB);
    }
  }

  // Ensure we never have borrow + supply balances of the same token on the same account
  function _repayDebtFromSupply(address _account, address _token) internal {

    uint burnAmount = Math.min(_debtOf(_token, _account), _supplyOf(_token, _account));

    if (burnAmount > 0) {
      _burnDebtShares(_token, _account, _debtToShares(_token, burnAmount));
      _burnSupplyShares(_token, _account, _supplyToShares(_token, burnAmount));
    }
  }

  function _uniCollectFees(address _account) internal returns(uint, uint) {
    uniPositions.approve(address(uniV3Helper), uniPosition[_account]);
    return uniV3Helper.collectFees(uniPosition[_account]);
  }

  function _mintSupplyAmount(address _token, address _account, uint _amount) internal returns(uint shares) {
    if (_amount > 0) {
      shares = _supplyToShares(_token, _amount);
      supplySharesOf[_token][_account] += shares;
      totalSupplyShares[_token] += shares;
      totalSupplyAmount[_token] += _amount;
    }
  }

  function _burnSupplyShares(address _token, address _account, uint _shares) internal returns(uint amount) {
    if (_shares > 0) {
      // Fix rounding error which can make issues during depositRepay / withdrawBorrow
      if (supplySharesOf[_token][_account] - _shares == 1) { _shares += 1; }
      amount = _sharesToSupply(_token, _shares);
      supplySharesOf[_token][_account] -= _shares;
      totalSupplyShares[_token] -= _shares;
      totalSupplyAmount[_token] -= amount;
    }
  }

  function _mintDebtAmount(address _token, address _account, uint _amount) internal returns(uint shares) {
    if (_amount > 0) {
      shares = _debtToShares(_token, _amount);
      debtSharesOf[_token][_account] += shares;
      totalDebtShares[_token] += shares;
      totalDebtAmount[_token] += _amount;
    }
  }

  function _burnDebtShares(address _token, address _account, uint _shares) internal returns(uint amount) {
    if (_shares > 0) {
      // Fix rounding error which can make issues during depositRepay / withdrawBorrow
      if (debtSharesOf[_token][_account] - _shares == 1) { _shares += 1; }
      amount = _sharesToDebt(_token, _shares);
      debtSharesOf[_token][_account] -= _shares;
      totalDebtShares[_token] -= _shares;
      totalDebtAmount[_token] -= amount;
    }
  }

  function _accrueDebt(address _token) internal returns(uint newDebt) {
    if (totalDebtAmount[_token] > 0) {
      uint blocksElapsed = block.number - lastBlockAccrued[_token];
      uint pendingInterestRate = _interestRatePerBlock(_token) * blocksElapsed;
      newDebt = totalDebtAmount[_token] * pendingInterestRate / 100e18;
      totalDebtAmount[_token] += newDebt;
    }
  }

  function _withdrawShares(address _token, uint _shares) internal {
    uint amount = _burnSupplyShares(_token, msg.sender, _shares);
    checkAccountHealth(msg.sender);
    emit Withdraw(msg.sender, _token, amount);
  }

  function _borrow(address _token, uint _amount) internal {

    require(supplySharesOf[_token][msg.sender] == 0, "LendingPair: cannot borrow supplied token");

    _checkBorrowEnabled();
    _checkBorrowLimits(_token, msg.sender, _amount);

    _mintDebtAmount(_token, msg.sender, _amount);
    checkAccountHealth(msg.sender);

    emit Borrow(msg.sender, _token, _amount);
  }

  function _repayShares(address _account, address _token, uint _shares) internal returns(uint amount) {
    amount = _burnDebtShares(_token, _account, _shares);
    emit Repay(_account, _token, amount);
  }

  function _deposit(address _account, address _token, uint _amount) internal {

    require(debtSharesOf[_token][_account] == 0, "LendingPair: cannot deposit borrowed token");

    _checkDepositsEnabled();
    _checkDepositLimit(_token, _amount);
    _mintSupplyAmount(_token, _account, _amount);

    emit Deposit(_account, _token, _amount);
  }

  function _createLpToken(address _lpTokenMaster, address _underlying) internal returns(address) {
    ILPTokenMaster newLPToken = ILPTokenMaster(_lpTokenMaster.clone());
    newLPToken.initialize(_underlying, address(lendingController));
    return address(newLPToken);
  }

  function _checkReserve(address _token) internal view {
    IERC20 token = IERC20(_token);

    uint balance = token.balanceOf(address(this));
    uint debt    = totalDebtAmount[_token];
    uint supply  = totalSupplyAmount[_token];
    uint fees    = pendingSystemFees[_token];

    require(int(balance) + int(debt) - int(supply) - int(fees) >= 0, "LendingPair: reserve check failed");
  }

  function _amountToShares(uint _totalShares, uint _totalAmount, uint _inputSupply) internal view returns(uint) {
    if (_totalShares > 0 && _totalAmount > 0) {
      return _inputSupply * _totalShares / _totalAmount;
    } else {
      return _inputSupply;
    }
  }

  function _sharesToAmount(uint _totalShares, uint _totalAmount, uint _inputShares) internal view returns(uint) {
    if (_totalShares > 0 && _totalAmount > 0) {
      return _inputShares * _totalAmount / _totalShares;
    } else {
      return _inputShares;
    }
  }

  function _debtToShares(address _token, uint _amount) internal view returns(uint) {
    return _amountToShares(totalDebtShares[_token], totalDebtAmount[_token], _amount);
  }

  function _sharesToDebt(address _token, uint _shares) internal view returns(uint) {
    return _sharesToAmount(totalDebtShares[_token], totalDebtAmount[_token], _shares);
  }

  function _supplyToShares(address _token, uint _amount) internal view returns(uint) {
    return _amountToShares(totalSupplyShares[_token], totalSupplyAmount[_token], _amount);
  }

  function _sharesToSupply(address _token, uint _shares) internal view returns(uint) {
    return _sharesToAmount(totalSupplyShares[_token], totalSupplyAmount[_token], _shares);
  }

  function _debtOf(address _token, address _account) internal view returns(uint) {
    return _sharesToDebt(_token, debtSharesOf[_token][_account]);
  }

  function _supplyOf(address _token, address _account) internal view returns(uint) {
    return _sharesToSupply(_token, supplySharesOf[_token][_account]);
  }

  function _interestRatePerBlock(address _token) internal view returns(uint) {
    return _interestRateModel().interestRatePerBlock(
      address(this),
      _token,
      totalSupplyAmount[_token],
      totalDebtAmount[_token]
    );
  }

  function _interestRateModel() internal view returns(IInterestRateModel) {
    return IInterestRateModel(lendingController.interestRateModel());
  }

  // Get borrow balance converted to the units of _returnToken
  function _borrowBalanceConverted(
    address _account,
    address _borrowedToken,
    address _returnToken,
    uint    _borrowPrice,
    uint    _returnPrice
  ) internal view returns(uint) {

    return _convertTokenValues(
      _borrowedToken,
      _returnToken,
      _debtOf(_borrowedToken, _account),
      _borrowPrice,
      _returnPrice
    );
  }

  // Get supply balance converted to the units of _returnToken
  function _supplyBalanceConverted(
    address _account,
    address _suppliedToken,
    address _returnToken,
    uint    _supplyPrice,
    uint    _returnPrice
  ) internal view returns(uint) {

    return _convertTokenValues(
      _suppliedToken,
      _returnToken,
      _supplyOf(_suppliedToken, _account),
      _supplyPrice,
      _returnPrice
    );
  }

  function _convertedCreditAUni(
    address _account,
    uint    _priceA,
    uint    _priceB,
    uint    _colFactorA,
    uint    _colFactorB
  ) internal view returns(uint) {

    if (uniPosition[_account] > 0) {

      (uint amountA, uint amountB) = _positionAmounts(uniPosition[_account], _priceA, _priceB);

      uint creditA = amountA * _colFactorA / 100e18;
      uint creditB = _convertTokenValues(tokenB, tokenA, amountB, _priceB, _priceA) * _colFactorB / 100e18;

      return (creditA + creditB);

    } else {
      return 0;
    }
  }

  function _positionAmounts(
    uint _position,
    uint _priceA,
    uint _priceB
  ) internal view returns(uint, uint) {

    uint priceA = 1 * 10 ** decimals[tokenB];
    uint priceB = _priceB * 10 ** decimals[tokenA] / _priceA;

    return uniV3Helper.positionAmounts(_position, priceA, priceB);
  }

  // Not calling priceOracle.convertTokenValues() to save gas by reusing already fetched prices
  function _convertTokenValues(
    address _fromToken,
    address _toToken,
    uint    _inputAmount,
    uint    _fromPrice,
    uint    _toPrice
  ) internal view returns(uint) {

    uint fromPrice = _fromPrice * 1e18 / 10 ** decimals[_fromToken];
    uint toPrice   = _toPrice   * 1e18 / 10 ** decimals[_toToken];

    return _inputAmount * fromPrice / toPrice;
  }

  function _validateToken(address _token) internal view {
    require(_token == tokenA || _token == tokenB, "LendingPair: invalid token");
  }

  function _validateUniPosition(uint _positionID) internal view {
    (, , address uniTokenA, address uniTokenB, , , , uint liquidity, , , ,) = positionManager.positions(_positionID);
    require(liquidity > 0, "LendingPair: liquidity > 0");
    _validateToken(uniTokenA);
    _validateToken(uniTokenB);
  }

  function _checkDepositsEnabled() internal view {
    require(lendingController.depositsEnabled(), "LendingPair: deposits disabled");
  }

  function _checkBorrowEnabled() internal view {
    require(lendingController.borrowingEnabled(), "LendingPair: borrowing disabled");
  }

  function _checkDepositLimit(address _token, uint _amount) internal view {
    uint depositLimit = lendingController.depositLimit(address(this), _token);

    if (depositLimit > 0) {
      require(
        totalSupplyAmount[_token] + _amount <= depositLimit,
        "LendingPair: deposit limit reached"
      );
    }
  }

  function _checkBorrowLimits(address _token, address _account, uint _amount) internal view {
    require(
      _debtOf(_token, _account) + _amount >= lendingController.minBorrow(_token),
      "LendingPair: borrow amount below minimum"
    );

    uint borrowLimit = lendingController.borrowLimit(address(this), _token);

    if (borrowLimit > 0) {
      require(totalDebtAmount[_token] + _amount <= borrowLimit, "LendingPair: borrow limit reached");
    }
  }

  function _lpRate(address _token) internal view returns(uint) {
    return _interestRateModel().lpRate(address(this), _token);
  }
}

