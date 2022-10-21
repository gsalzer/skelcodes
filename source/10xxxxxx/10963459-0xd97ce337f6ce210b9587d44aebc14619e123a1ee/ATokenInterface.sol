pragma solidity ^0.5.16;

import "./AegisTokenCommon.sol";
import "./InterestRateModel.sol";
import "./AegisComptrollerInterface.sol";

/**
 * @title aToken interface
 * @author Aegis
 */
contract ATokenInterface is AegisTokenCommon {
    bool public constant aToken = true;

    /**
     * @notice Emitted when interest is accrued
     */
    event AccrueInterest(uint _cashPrior, uint _interestAccumulated, uint _borrowIndex, uint _totalBorrows);

    /**
     * @notice Emitted when tokens are minted
     */
    event Mint(address _minter, uint _mintAmount, uint _mintTokens);

    /**
     * @notice Emitted when tokens are redeemed
     */
    event Redeem(address _redeemer, uint _redeemAmount, uint _redeemTokens);

    /**
     * @notice Emitted when underlying is borrowed
     */
    event Borrow(address _borrower, uint _borrowAmount, uint _accountBorrows, uint _totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address _payer, address _borrower, uint _repayAmount, uint _accountBorrows, uint _totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address _liquidator, address _borrower, uint _repayAmount, address _aTokenCollateral, uint _seizeTokens);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address _old, address _new);

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when comptroller is changed
     */
    event NewComptroller(AegisComptrollerInterface _oldComptroller, AegisComptrollerInterface _newComptroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel _oldInterestRateModel, InterestRateModel _newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint _oldReserveFactorMantissa, uint _newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address _benefactor, uint _addAmount, uint _newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address _admin, uint _reduceAmount, uint _newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed _from, address indexed _to, uint _amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed _owner, address indexed _spender, uint _amount);

    /**
     * @notice Failure event
     */
    event Failure(uint _error, uint _info, uint _detail);


    function transfer(address _dst, uint _amount) external returns (bool);
    function transferFrom(address _src, address _dst, uint _amount) external returns (bool);
    function approve(address _spender, uint _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    function balanceOfUnderlying(address _owner) external returns (uint);
    function getAccountSnapshot(address _account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address _account) external returns (uint);
    function borrowBalanceStored(address _account) public view returns (uint);
    function exchangeRateCurrent() public returns (uint);
    function exchangeRateStored() public view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() public returns (uint);
    function seize(address _liquidator, address _borrower, uint _seizeTokens) external returns (uint);


    function _acceptAdmin() external returns (uint);
    function _setComptroller(AegisComptrollerInterface _newComptroller) public returns (uint);
    function _setReserveFactor(uint _newReserveFactorMantissa) external returns (uint);
    function _reduceReserves(uint _reduceAmount, address payable _account) external returns (uint);
    function _setInterestRateModel(InterestRateModel _newInterestRateModel) public returns (uint);
}
