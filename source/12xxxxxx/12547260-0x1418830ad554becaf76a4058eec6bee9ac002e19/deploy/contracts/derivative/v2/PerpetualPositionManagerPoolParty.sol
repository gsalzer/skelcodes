// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  MintableBurnableIERC20
} from '../common/interfaces/MintableBurnableIERC20.sol';
import {
  IDerivativeDeployment
} from '../common/interfaces/IDerivativeDeployment.sol';
import {IDerivativeMain} from '../common/interfaces/IDerivativeMain.sol';
import {
  OracleInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/OracleInterface.sol';
import {
  IdentifierWhitelistInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/IdentifierWhitelistInterface.sol';
import {
  AdministrateeInterface
} from '../../../@jarvis-network/uma-core/contracts/oracle/interfaces/AdministrateeInterface.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {IDerivative} from '../common/interfaces/IDerivative.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  OracleInterfaces
} from '../../../@jarvis-network/uma-core/contracts/oracle/implementation/Constants.sol';
import {SafeMath} from '../../../@openzeppelin/contracts/math/SafeMath.sol';
import {SafeERC20} from '../../../@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {
  FixedPoint
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/FixedPoint.sol';
import {
  PerpetualPositionManagerPoolPartyLib
} from './PerpetualPositionManagerPoolPartyLib.sol';
import {AccessControl} from '../../../@openzeppelin/contracts/access/AccessControl.sol';
import {
  AddressWhitelist
} from '../../../@jarvis-network/uma-core/contracts/common/implementation/AddressWhitelist.sol';
import {FeePayerParty} from '../common/FeePayerParty.sol';

/**
 * @title Financial contract with priceless position management.
 * @notice Handles positions for multiple sponsors in an optimistic (i.e., priceless) way without relying
 * on a price feed. On construction, deploys a new ERC20, managed by this contract, that is the synthetic token.
 */
contract PerpetualPositionManagerPoolParty is
  IDerivative,
  AccessControl,
  FeePayerParty
{
  using FixedPoint for FixedPoint.Unsigned;
  using SafeERC20 for IERC20;
  using SafeERC20 for MintableBurnableIERC20;
  using PerpetualPositionManagerPoolPartyLib for PositionData;
  using PerpetualPositionManagerPoolPartyLib for PositionManagerData;

  bytes32 public constant POOL_ROLE = keccak256('Pool');

  /**
   * @notice Construct the PerpetualPositionManager.
   * @dev Deployer of this contract should consider carefully which parties have ability to mint and burn
   * the synthetic tokens referenced by `_tokenAddress`. This contract's security assumes that no external accounts
   * can mint new tokens, which could be used to steal all of this contract's locked collateral.
   * We recommend to only use synthetic token contracts whose sole Owner role (the role capable of adding & removing roles)
   * is assigned to this contract, whose sole Minter role is assigned to this contract, and whose
   * total supply is 0 prior to construction of this contract.
   * @param withdrawalLiveness liveness delay, in seconds, for pending withdrawals.
   * @param collateralAddress ERC20 token used as collateral for all positions.
   * @param tokenAddress ERC20 token used as synthetic token.
   * @param finderAddress UMA protocol Finder used to discover other protocol contracts.
   * @param priceFeedIdentifier registered in the DVM for the synthetic.
   * @param minSponsorTokens minimum amount of collateral that must exist at any time in a position.
   * @param timerAddress Contract that stores the current time in a testing environment. Set to 0x0 for production.
   * @param excessTokenBeneficiary Beneficiary to send all excess token balances that accrue in the contract.
   * @param synthereumFinder The SynthereumFinder contract
   */
  struct PositionManagerParams {
    uint256 withdrawalLiveness;
    address collateralAddress;
    address tokenAddress;
    address finderAddress;
    bytes32 priceFeedIdentifier;
    FixedPoint.Unsigned minSponsorTokens;
    address timerAddress;
    address excessTokenBeneficiary;
    ISynthereumFinder synthereumFinder;
  }

  //Describe role structure
  struct Roles {
    address[] admins;
    address[] pools;
  }

  // Represents a single sponsor's position. All collateral is held by this contract.
  // This struct acts as bookkeeping for how much of that collateral is allocated to each sponsor.
  struct PositionData {
    FixedPoint.Unsigned tokensOutstanding;
    // Tracks pending withdrawal requests. A withdrawal request is pending if `withdrawalRequestPassTimestamp != 0`.
    uint256 withdrawalRequestPassTimestamp;
    FixedPoint.Unsigned withdrawalRequestAmount;
    // Raw collateral value. This value should never be accessed directly -- always use _getFeeAdjustedCollateral().
    // To add or remove collateral, use _addCollateral() and _removeCollateral().
    FixedPoint.Unsigned rawCollateral;
  }

  struct GlobalPositionData {
    // Keep track of the total collateral and tokens across all positions to enable calculating the
    // global collateralization ratio without iterating over all positions.
    FixedPoint.Unsigned totalTokensOutstanding;
    // Similar to the rawCollateral in PositionData, this value should not be used directly.
    // _getFeeAdjustedCollateral(), _addCollateral() and _removeCollateral() must be used to access and adjust.
    FixedPoint.Unsigned rawTotalPositionCollateral;
  }

  struct PositionManagerData {
    // SynthereumFinder contract
    ISynthereumFinder synthereumFinder;
    // Synthetic token created by this contract.
    MintableBurnableIERC20 tokenCurrency;
    // Unique identifier for DVM price feed ticker.
    bytes32 priceIdentifier;
    // Time that has to elapse for a withdrawal request to be considered passed, if no liquidations occur.
    // !!Note: The lower the withdrawal liveness value, the more risk incurred by the contract.
    // Extremely low liveness values increase the chance that opportunistic invalid withdrawal requests
    // expire without liquidation, thereby increasing the insolvency risk for the contract as a whole. An insolvent
    // contract is extremely risky for any sponsor or synthetic token holder for the contract.
    uint256 withdrawalLiveness;
    // Minimum number of tokens in a sponsor's position.
    FixedPoint.Unsigned minSponsorTokens;
    // Expiry price pulled from the DVM in the case of an emergency shutdown.
    FixedPoint.Unsigned emergencyShutdownPrice;
    // Timestamp used in case of emergency shutdown.
    uint256 emergencyShutdownTimestamp;
    // The excessTokenBeneficiary of any excess tokens added to the contract.
    address excessTokenBeneficiary;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  // Maps sponsor addresses to their positions. Each sponsor can have only one position.
  mapping(address => PositionData) public positions;

  GlobalPositionData public globalPositionData;

  PositionManagerData public positionManagerData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Deposit(address indexed sponsor, uint256 indexed collateralAmount);
  event Withdrawal(address indexed sponsor, uint256 indexed collateralAmount);
  event RequestWithdrawal(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalExecuted(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event RequestWithdrawalCanceled(
    address indexed sponsor,
    uint256 indexed collateralAmount
  );
  event PositionCreated(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event NewSponsor(address indexed sponsor);
  event EndedSponsorPosition(address indexed sponsor);
  event Redeem(
    address indexed sponsor,
    uint256 indexed collateralAmount,
    uint256 indexed tokenAmount
  );
  event Repay(
    address indexed sponsor,
    uint256 indexed numTokensRepaid,
    uint256 indexed newTokenCount
  );
  event EmergencyShutdown(address indexed caller, uint256 shutdownTimestamp);
  event SettleEmergencyShutdown(
    address indexed caller,
    uint256 indexed collateralReturned,
    uint256 indexed tokensBurned
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyPool() {
    require(hasRole(POOL_ROLE, msg.sender), 'Sender must be a pool');
    _;
  }

  modifier onlyCollateralizedPosition(address sponsor) {
    _onlyCollateralizedPosition(sponsor);
    _;
  }

  modifier notEmergencyShutdown() {
    _notEmergencyShutdown();
    _;
  }

  modifier isEmergencyShutdown() {
    _isEmergencyShutdown();
    _;
  }

  modifier noPendingWithdrawal(address sponsor) {
    _positionHasNoPendingWithdrawal(sponsor);
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Construct the PerpetualPositionManager.
   * @param _positionManagerData Input parameters of PositionManager (see PositionManagerData struct)
   * @param _roles List of admin and token sponsors roles
   */
  constructor(
    PositionManagerParams memory _positionManagerData,
    Roles memory _roles
  )
    public
    FeePayerParty(
      _positionManagerData.collateralAddress,
      _positionManagerData.finderAddress,
      _positionManagerData.timerAddress
    )
    nonReentrant()
  {
    require(
      _getIdentifierWhitelist().isIdentifierSupported(
        _positionManagerData.priceFeedIdentifier
      ),
      'Unsupported price identifier'
    );
    require(
      _getCollateralWhitelist().isOnWhitelist(
        _positionManagerData.collateralAddress
      ),
      'Collateral not whitelisted'
    );
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(POOL_ROLE, DEFAULT_ADMIN_ROLE);
    for (uint256 j = 0; j < _roles.admins.length; j++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _roles.admins[j]);
    }
    for (uint256 j = 0; j < _roles.pools.length; j++) {
      _setupRole(POOL_ROLE, _roles.pools[j]);
    }
    positionManagerData.synthereumFinder = _positionManagerData
      .synthereumFinder;
    positionManagerData.withdrawalLiveness = _positionManagerData
      .withdrawalLiveness;
    positionManagerData.tokenCurrency = MintableBurnableIERC20(
      _positionManagerData.tokenAddress
    );
    positionManagerData.minSponsorTokens = _positionManagerData
      .minSponsorTokens;
    positionManagerData.priceIdentifier = _positionManagerData
      .priceFeedIdentifier;
    positionManagerData.excessTokenBeneficiary = _positionManagerData
      .excessTokenBeneficiary;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Transfers `collateralAmount` of `feePayerData.collateralCurrency` into the caller's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of `feePayerData.collateralCurrency`.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function deposit(FixedPoint.Unsigned memory collateralAmount)
    external
    override
  {
    // This is just a thin wrapper over depositTo that specified the sender as the sponsor.
    depositTo(msg.sender, collateralAmount);
  }

  /**
   * @notice Transfers `collateralAmount` of `feePayerData.collateralCurrency` from the sponsor's position to the sponsor.
   * @dev Reverts if the withdrawal puts this position's collateralization ratio below the global collateralization
   * ratio. In that case, use `requestWithdrawal`. Might not withdraw the full requested amount to account for precision loss.
   * @param collateralAmount is the amount of collateral to withdraw.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdraw(FixedPoint.Unsigned memory collateralAmount)
    external
    override
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData.withdraw(
      globalPositionData,
      collateralAmount,
      feePayerData
    );
  }

  /**
   * @notice Starts a withdrawal request that, if passed, allows the sponsor to withdraw` from their position.
   * @dev The request will be pending for `withdrawalLiveness`, during which the position can be liquidated.
   * @param collateralAmount the amount of collateral requested to withdraw
   */
  function requestWithdrawal(FixedPoint.Unsigned memory collateralAmount)
    external
    override
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    nonReentrant()
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.requestWithdrawal(
      positionManagerData,
      collateralAmount,
      actualTime,
      feePayerData
    );
  }

  /**
   * @notice After a passed withdrawal request (i.e., by a call to `requestWithdrawal` and waiting
   * `withdrawalLiveness`), withdraws `positionData.withdrawalRequestAmount` of collateral currency.
   * @dev Might not withdraw the full requested amount in order to account for precision loss or if the full requested
   * amount exceeds the collateral in the position (due to paying fees).
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function withdrawPassedRequest()
    external
    override
    onlyPool()
    notEmergencyShutdown()
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    uint256 actualTime = getCurrentTime();
    PositionData storage positionData = _getPositionData(msg.sender);
    amountWithdrawn = positionData.withdrawPassedRequest(
      globalPositionData,
      actualTime,
      feePayerData
    );
  }

  /**
   * @notice Cancels a pending withdrawal request.
   */
  function cancelWithdrawal()
    external
    override
    onlyPool()
    notEmergencyShutdown()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.cancelWithdrawal();
  }

  /**
   * @notice Creates tokens by creating a new position or by augmenting an existing position. Pulls `collateralAmount
   * ` into the sponsor's position and mints `numTokens` of `tokenCurrency`.
   * @dev This contract must have the Minter role for the `tokenCurrency`.
   * @dev Reverts if minting these tokens would put the position's collateralization ratio below the
   * global collateralization ratio. This contract must be approved to spend at least `collateralAmount` of
   * `feePayerData.collateralCurrency`.
   * @param collateralAmount is the number of collateral tokens to collateralize the position with
   * @param numTokens is the number of tokens to mint from the position.
   */
  function create(
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) external override onlyPool() notEmergencyShutdown() fees() nonReentrant() {
    PositionData storage positionData = positions[msg.sender];

    positionData.create(
      globalPositionData,
      positionManagerData,
      collateralAmount,
      numTokens,
      feePayerData
    );
  }

  /**
   * @notice Burns `numTokens` of `tokenCurrency` and sends back the proportional amount of `feePayerData.collateralCurrency`.
   * @dev Can only be called by a token sponsor. Might not redeem the full proportional amount of collateral
   * in order to account for precision loss. This contract must be approved to spend at least `numTokens` of
   * `tokenCurrency`.
   * @dev This contract must have the Burner role for the `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function redeem(FixedPoint.Unsigned memory numTokens)
    external
    override
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = _getPositionData(msg.sender);

    amountWithdrawn = positionData.redeeem(
      globalPositionData,
      positionManagerData,
      numTokens,
      feePayerData,
      msg.sender
    );
  }

  /**
   * @notice Burns `numTokens` of `tokenCurrency` to decrease sponsors position size, without sending back `feePayerData.collateralCurrency`.
   * This is done by a sponsor to increase position CR. Resulting size is bounded by minSponsorTokens.
   * @dev Can only be called by token sponsor. This contract must be approved to spend `numTokens` of `tokenCurrency`.
   * @dev This contract must have the Burner role for the `tokenCurrency`.
   * @param numTokens is the number of tokens to be burnt for a commensurate amount of collateral.
   */
  function repay(FixedPoint.Unsigned memory numTokens)
    external
    override
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(msg.sender)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(msg.sender);
    positionData.repay(globalPositionData, positionManagerData, numTokens);
  }

  /**
   * @notice If the contract is emergency shutdown then all token holders and sponsors can redeem their tokens or
   * remaining collateral for underlying at the prevailing price defined by a DVM vote.
   * @dev This burns all tokens from the caller of `tokenCurrency` and sends back the resolved settlement value of
   * `feePayerData.collateralCurrency`. Might not redeem the full proportional amount of collateral in order to account for
   * precision loss. This contract must be approved to spend `tokenCurrency` at least up to the caller's full balance.
   * @dev This contract must have the Burner role for the `tokenCurrency`.
   * @return amountWithdrawn The actual amount of collateral withdrawn.
   */
  function settleEmergencyShutdown()
    external
    override
    onlyPool()
    isEmergencyShutdown()
    fees()
    nonReentrant()
    returns (FixedPoint.Unsigned memory amountWithdrawn)
  {
    PositionData storage positionData = positions[msg.sender];
    amountWithdrawn = positionData.settleEmergencyShutdown(
      globalPositionData,
      positionManagerData,
      feePayerData
    );
  }

  /**
   * @notice Premature contract settlement under emergency circumstances.
   * @dev Only the governor can call this function as they are permissioned within the `FinancialContractAdmin`.
   * Upon emergency shutdown, the contract settlement time is set to the shutdown time. This enables withdrawal
   * to occur via the `settleEmergencyShutdown` function.
   */
  function emergencyShutdown()
    external
    override(IDerivativeMain, AdministrateeInterface)
    notEmergencyShutdown()
    nonReentrant()
  {
    require(
      msg.sender ==
        positionManagerData.synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.Manager
        ) ||
        msg.sender == _getFinancialContractsAdminAddress(),
      'Caller must be a Synthereum manager or the UMA governor'
    );
    positionManagerData.emergencyShutdownTimestamp = getCurrentTime();
    positionManagerData.requestOraclePrice(
      positionManagerData.emergencyShutdownTimestamp,
      feePayerData
    );
    emit EmergencyShutdown(
      msg.sender,
      positionManagerData.emergencyShutdownTimestamp
    );
  }

  /** @notice Remargin function
   */
  function remargin()
    external
    override(IDerivativeMain, AdministrateeInterface)
  {
    return;
  }

  /**
   * @notice Drains any excess balance of the provided ERC20 token to a pre-selected beneficiary.
   * @dev This will drain down to the amount of tracked collateral and drain the full balance of any other token.
   * @param token address of the ERC20 token whose excess balance should be drained.
   */
  function trimExcess(IERC20 token)
    external
    override
    nonReentrant()
    returns (FixedPoint.Unsigned memory amount)
  {
    FixedPoint.Unsigned memory pfcAmount = _pfc();
    amount = positionManagerData.trimExcess(token, pfcAmount, feePayerData);
  }

  /**
   * @notice Delete a TokenSponsor position (This function can only be called by the contract itself)
   * @param sponsor address of the TokenSponsor.
   */
  function deleteSponsorPosition(address sponsor) external onlyThisContract {
    delete positions[sponsor];
  }

  /**
   * @notice Accessor method for a sponsor's collateral.
   * @dev This is necessary because the struct returned by the positions() method shows
   * rawCollateral, which isn't a user-readable value.
   * @param sponsor address whose collateral amount is retrieved.
   * @return collateralAmount amount of collateral within a sponsors position.
   */
  function getCollateral(address sponsor)
    external
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory collateralAmount)
  {
    collateralAmount = positions[sponsor]
      .rawCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
  }

  /**
   * @notice Get SynthereumFinder contract address
   * @return finder SynthereumFinder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = positionManagerData.synthereumFinder;
  }

  /**
   * @notice Get synthetic token currency
   * @return token Synthetic token
   */
  function tokenCurrency() external view override returns (IERC20 token) {
    token = positionManagerData.tokenCurrency;
  }

  /**
   * @notice Get synthetic token symbol
   * @return symbol Synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(positionManagerData.tokenCurrency))
      .symbol();
  }

  /**
   * @notice Get synthetic token price identifier registered with UMA DVM
   * @return identifier Synthetic token price identifier
   */
  function priceIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = positionManagerData.priceIdentifier;
  }

  /**
   * @notice Accessor method for the total collateral stored within the PerpetualPositionManagerPoolParty.
   * @return totalCollateral amount of all collateral within the position manager.
   */
  function totalPositionCollateral()
    external
    view
    override
    nonReentrantView()
    returns (FixedPoint.Unsigned memory totalCollateral)
  {
    totalCollateral = globalPositionData
      .rawTotalPositionCollateral
      .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier);
  }

  /**
   * @notice Get the currently minted synthetic tokens from all derivatives
   * @return totalTokens Total amount of synthetic tokens minted
   */
  function totalTokensOutstanding()
    external
    view
    override
    returns (FixedPoint.Unsigned memory totalTokens)
  {
    totalTokens = globalPositionData.totalTokensOutstanding;
  }

  /**
   * @notice Get the price of synthetic token set by DVM after emergencyShutdown call
   * @return Price of synthetic token
   */
  function emergencyShutdownPrice()
    external
    view
    override
    isEmergencyShutdown()
    returns (FixedPoint.Unsigned memory)
  {
    return positionManagerData.emergencyShutdownPrice;
  }

  /**
   * @notice Accessor method for the list of members with admin role
   * @return array of addresses with admin role
   */
  function getAdminMembers() external view override returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(DEFAULT_ADMIN_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(DEFAULT_ADMIN_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  /**
   * @notice Accessor method for the list of members with pool role
   * @return array of addresses with pool role
   */
  function getPoolMembers() external view override returns (address[] memory) {
    uint256 numberOfMembers = getRoleMemberCount(POOL_ROLE);
    address[] memory members = new address[](numberOfMembers);
    for (uint256 j = 0; j < numberOfMembers; j++) {
      address newMember = getRoleMember(POOL_ROLE, j);
      members[j] = newMember;
    }
    return members;
  }

  /**
   * @notice Transfers `collateralAmount` of `feePayerData.collateralCurrency` into the specified sponsor's position.
   * @dev Increases the collateralization level of a position after creation. This contract must be approved to spend
   * at least `collateralAmount` of `feePayerData.collateralCurrency`.
   * @param sponsor the sponsor to credit the deposit to.
   * @param collateralAmount total amount of collateral tokens to be sent to the sponsor's position.
   */
  function depositTo(
    address sponsor,
    FixedPoint.Unsigned memory collateralAmount
  )
    public
    override
    onlyPool()
    notEmergencyShutdown()
    noPendingWithdrawal(sponsor)
    fees()
    nonReentrant()
  {
    PositionData storage positionData = _getPositionData(sponsor);

    positionData.depositTo(
      globalPositionData,
      collateralAmount,
      feePayerData,
      sponsor
    );
  }

  /**
   * @notice Get the collateralCurrency backing a synthetic token
   * @return collateral Collateral used for minting synthetic tokens
   */
  function collateralCurrency()
    public
    view
    override(IDerivativeDeployment, FeePayerParty)
    returns (IERC20 collateral)
  {
    collateral = FeePayerParty.collateralCurrency();
  }

  //----------------------------------------
  // Internal functions
  //----------------------------------------

  function _pfc()
    internal
    view
    virtual
    override
    returns (FixedPoint.Unsigned memory)
  {
    return
      globalPositionData.rawTotalPositionCollateral.getFeeAdjustedCollateral(
        feePayerData.cumulativeFeeMultiplier
      );
  }

  function _getPositionData(address sponsor)
    internal
    view
    onlyCollateralizedPosition(sponsor)
    returns (PositionData storage)
  {
    return positions[sponsor];
  }

  function _getIdentifierWhitelist()
    internal
    view
    returns (IdentifierWhitelistInterface)
  {
    return
      IdentifierWhitelistInterface(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.IdentifierWhitelist
        )
      );
  }

  function _getCollateralWhitelist() internal view returns (AddressWhitelist) {
    return
      AddressWhitelist(
        feePayerData.finder.getImplementationAddress(
          OracleInterfaces.CollateralWhitelist
        )
      );
  }

  // Fetches a resolved Oracle price from the Oracle. Reverts if the Oracle hasn't resolved for this request.
  // These internal functions are supposed to act identically to modifiers, but re-used modifiers

  function _onlyCollateralizedPosition(address sponsor) internal view {
    require(
      positions[sponsor]
        .rawCollateral
        .getFeeAdjustedCollateral(feePayerData.cumulativeFeeMultiplier)
        .isGreaterThan(0),
      'Position has no collateral'
    );
  }

  function _notEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp == 0,
      'Contract emergency shutdown'
    );
  }

  function _isEmergencyShutdown() internal view {
    require(
      positionManagerData.emergencyShutdownTimestamp != 0,
      'Contract not emergency shutdown'
    );
  }

  // Note: This checks whether an already existing position has a pending withdrawal. This cannot be used on the
  // `create` method because it is possible that `create` is called on a new position (i.e. one without any collateral
  // or tokens outstanding) which would fail the `onlyCollateralizedPosition` modifier on `_getPositionData`.
  function _positionHasNoPendingWithdrawal(address sponsor) internal view {
    require(
      _getPositionData(sponsor).withdrawalRequestPassTimestamp == 0,
      'Pending withdrawal'
    );
  }

  function _getFinancialContractsAdminAddress()
    internal
    view
    returns (address)
  {
    return
      feePayerData.finder.getImplementationAddress(
        OracleInterfaces.FinancialContractsAdmin
      );
  }
}

