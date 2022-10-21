/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '../../0xerc1155/interfaces/IERC1155.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../0xerc1155/utils/SafeMath.sol';
import '../../0xerc1155/access/AccessControl.sol';

import '../investment/interfaces/IRewardHandler.sol';
import '../token/interfaces/IWOWSERC1155.sol';
import '../utils/TokenIds.sol';

import './interfaces/IBooster.sol';

contract Booster is IBooster, AccessControl {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using TokenIds for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant CONTROLLER_ROLE = bytes32('CONTROLLER');

  // 30 days in seconds multiplied by 10 (10% per month)
  uint256 private constant MONTHLY_REWARD = 25920000;

  // Maximum rewards provided from tokenomics
  uint256 private constant MAX_TOKENOMICS_REWARDS = 7500000000000000000000;

  // SECONDS PER YEAR
  uint256 private constant SECONDS_PER_YEAR = 360 * 86400;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // The rewardHandler to distribute rewards
  IRewardHandler public rewardHandler;

  // The SFT contract to validate recipients
  IWOWSERC1155 public sftHolder;

  // Our timelock
  struct TimeLock {
    uint256 totalAmount;
    uint256 pendingAmount;
    uint256 providedAmount;
    uint256 last;
    uint256 end;
    uint256 apr;
    uint32 fee;
  }
  mapping(address => TimeLock) public timeLocks;

  // Reward definition (1 / 3 / 6 month)
  struct RewardDefinition {
    uint256 length; // in seconds
    uint256 apr; // 1E18 == 100%
  }
  RewardDefinition[] public rewardDefinitions;

  // Overall provided rewards
  uint256 public rewardsProvided;

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'B: Only admin');
    _;
  }

  modifier onlyController() {
    require(hasRole(CONTROLLER_ROLE, _msgSender()), 'B: Only controller');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Temporary tokens owned by recipient were locked
   *
   * Tokens are owned by recipient for a specific duration of seconds.
   *
   * @param recipient The recipient of the rewards
   * @param amountIn The amount of tokens in
   * @param amountLocked The amount of tokens locked (amount plus reward)
   */
  event TokensLocked(
    address indexed recipient,
    uint256 amountIn,
    uint256 amountLocked
  );

  /**
   * @dev More amount was added into existing lock pool
   *
   * @param recipient The SFT receiving the rewards
   * @param amount The amount of tokens claimed
   * @param amountLocked The amount of tokens locked
   */
  event MoreAdded(
    address indexed recipient,
    uint256 amount,
    uint256 amountLocked
  );

  /**
   * @dev Rrewards were claimed either into wallet or re-locked
   *
   * @param recipient The recipient of the rewards
   * @param amount The amount of tokens claimed
   */
  event RewardsClaimed(address indexed recipient, uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructs implementation part and provides admin access
   * for a later selfDestruct call.
   */
  constructor(address admin) {
    // For administrative calls
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  /**
   * @dev One time initializer for proxy
   */
  function initialize(address admin, address rewardHandler_) external {
    // Validate parameters
    require(
      getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0,
      'B: Already initialized'
    );

    // For administrative calls
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
    _setRewardHandler(rewardHandler_);

    // Reward definition: 180 days / 175% APR
    rewardDefinitions.push(RewardDefinition(15552000, 1750000000000000000));

    // Reward definition: 90 days / 130% APR
    rewardDefinitions.push(RewardDefinition(7776000, 1300000000000000000));

    // Reward definition: 30 days / 100% APR
    rewardDefinitions.push(RewardDefinition(2592000, 1000000000000000000));
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IBooster}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IBooster-getRewardInfo}
   */
  function getRewardInfo(uint256[] memory tokenIds)
    external
    view
    override
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    )
  {
    locked = new uint256[](tokenIds.length);
    pending = new uint256[](tokenIds.length);
    apr = new uint256[](tokenIds.length);
    secsLeft = new uint256[](tokenIds.length);

    uint256 ts = _getTimestamp();

    for (uint256 i = 0; i < tokenIds.length; ++i) {
      address cfolio = sftHolder.tokenIdToAddress(tokenIds[i].toSftTokenId());
      require(cfolio != address(0), 'B: Invalid tokenId');

      TimeLock storage currentLock = timeLocks[cfolio];
      locked[i] = currentLock.totalAmount;
      pending[i] = _getPendingAmount(currentLock, ts);
      apr[i] = currentLock.apr;
      secsLeft[i] = currentLock.end >= ts
        ? currentLock.end.sub(ts)
        : uint256(-1);
    }
  }

  /**
   * @dev See {IBooster-distributeFromFarm}
   */
  function distributeFromFarm(
    address, /* farm*/
    address recipient,
    uint256 amount,
    uint32 fee
  ) external override onlyController {
    // Validate input
    require(recipient != address(0), 'B: Invalid recipient');

    if (sftHolder.addressToTokenId(recipient) != uint256(-1)) {
      // Prepare locking amount into SFT
      TimeLock storage currentLock = timeLocks[recipient];

      if (currentLock.end != 0) {
        uint256 ts = _getTimestamp();

        // Update pending rewards
        _updatePendingRewards(currentLock, ts);

        // Add more
        require(currentLock.fee == fee, 'B: Fee change');

        // Add amount to total
        _addMore(recipient, currentLock, ts, amount);
      } else {
        // Validate state
        require(
          currentLock.totalAmount == 0 || currentLock.fee == fee,
          'B: Fee mismatch'
        );

        // Prepare for a new lock
        currentLock.fee = fee;
        currentLock.totalAmount = currentLock.totalAmount.add(amount);
      }
    } else {
      rewardHandler.distribute2(recipient, amount, fee);
    }
  }

  /**
   * @dev See {IBooster-lock}
   */
  function lock(address recipient, uint256 lockPeriod)
    external
    override
    onlyController
  {
    uint256 ts = _getTimestamp();

    TimeLock storage currentLock = timeLocks[recipient];

    // Verify that we have already updated lock (from preceeding
    // {distributeFromFarm} call)
    require(currentLock.end == 0 || currentLock.last == ts, 'B: Sync failure');

    if (currentLock.end == 0) {
      // Start a new lock session. Calculate the amount we provide.
      for (uint256 i = 0; i < rewardDefinitions.length; ++i) {
        if (lockPeriod >= rewardDefinitions[i].length) {
          uint256 reward = (
            currentLock.totalAmount.mul(rewardDefinitions[i].length).mul(
              rewardDefinitions[i].apr
            )
          ).div(SECONDS_PER_YEAR.mul(1E18));

          currentLock.totalAmount = currentLock.totalAmount.add(reward);
          currentLock.end = ts + rewardDefinitions[i].length;
          currentLock.apr = rewardDefinitions[i].apr;
          currentLock.last = ts;

          rewardsProvided.add(reward);

          // Validate state
          _verifyRewardsProvided();

          // Dispatch event
          emit TokensLocked(
            recipient,
            currentLock.totalAmount.sub(reward),
            currentLock.totalAmount
          );

          // Candidate found, return
          return;
        }
      }

      // We never should reach this line
      revert('B: LockPeriod wrong');
    }
  }

  /**
   * @dev See {IBooster-claimRewards}
   */
  function claimRewards(uint256 sftTokenId, bool reLock) external override {
    // Validate access
    address cfolio = sftHolder.tokenIdToAddress(sftTokenId);
    require(cfolio != address(0), 'B: Invalid cfolio');
    require(
      IERC1155(address(sftHolder)).balanceOf(_msgSender(), sftTokenId) == 1,
      'B: Access denied'
    );

    TimeLock storage currentLock = timeLocks[cfolio];
    uint256 ts = _getTimestamp();

    _updatePendingRewards(currentLock, ts);

    uint256 claimable = currentLock.pendingAmount;
    currentLock.pendingAmount = 0;
    currentLock.providedAmount.add(claimable);

    // Dispatch event
    emit RewardsClaimed(cfolio, claimable);

    // Update state
    if (reLock) {
      _addMore(cfolio, currentLock, ts, claimable);
    } else {
      rewardHandler.distribute2(_msgSender(), claimable, currentLock.fee);
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Maintanance functions
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Self destruct implementation contract
   */
  function destructContract(address payable newContract) external onlyAdmin {
    // slither-disable-next-line suicidal
    selfdestruct(newContract);
  }

  /**
   * @dev Set reward handler in case it will be upgraded
   */
  function setRewardHandler(address rewardHandler_) external onlyAdmin {
    _setRewardHandler(rewardHandler_);
  }

  /**
   * @dev Set sftHolder contract which is deployed after Booster
   */
  function setSftHolder(address sftHolder_) external onlyAdmin {
    // Validate input
    require(sftHolder_ != address(0), 'B: Invalid sftHolder');

    // Update state
    sftHolder = IWOWSERC1155(sftHolder_);
  }

  /**
   * @dev Replace reward definition.
   * Durations are required to be in descending order
   */
  function setRewardDefinition(
    uint256[] calldata durations,
    uint256[] calldata aprs
  ) external onlyAdmin {
    // Validate input
    require(durations.length == aprs.length, 'B: Length mismatch');

    // Update state
    delete (rewardDefinitions);
    for (uint256 i = 0; i < durations.length; ++i) {
      require(i == 0 || durations[i] > durations[i - 1], 'B: Wrong sorting');
      rewardDefinitions.push(RewardDefinition(durations[i], aprs[i]));
    }
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Helper function to avoid disabling solhint in several places
   */
  function _getTimestamp() private view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp;
  }

  /**
   * @dev Internal setRewardhandler which checks for valid address
   */
  function _setRewardHandler(address rewardHandler_) internal {
    // Validate input
    require(rewardHandler_ != address(0), 'B: Invalid rewardHandler');

    // Update state
    rewardHandler = IRewardHandler(rewardHandler_);
  }

  /**
   * @dev Add more amount into existing lock pool
   *
   * Function will revert in case lock is closed because lock_.end is 0
   * and every subtraction with ts > 0 will fail in SafeMath
   */
  function _addMore(
    address recipient,
    TimeLock storage lock_,
    uint256 ts,
    uint256 amount
  ) private {
    // Following line reverts in SafeMath if timestamps are invalid
    uint256 reward = (amount.mul(lock_.end.sub(ts)).mul(lock_.apr)).div(
      SECONDS_PER_YEAR.mul(1E18)
    );

    // Update state
    lock_.totalAmount = lock_.totalAmount.add(amount).add(reward);
    rewardsProvided.add(reward);

    // Validate state
    _verifyRewardsProvided();

    // Dispatch event
    emit MoreAdded(recipient, amount, amount.add(reward));
  }

  /**
   * @dev Write all pending rewards into pendingAmount so we can
   * safely add more amounts or finalize the lock pool.
   */
  function _updatePendingRewards(TimeLock storage lock_, uint256 ts) private {
    lock_.pendingAmount = _getPendingAmount(lock_, ts);
    if (lock_.end != 0) {
      if (ts >= lock_.end) {
        lock_.end = 0;
        lock_.totalAmount = 0;
        lock_.providedAmount = 0;
      } else {
        lock_.last = ts;
      }
    }
  }

  /**
   * @dev Calculate the current pending amount
   */
  function _getPendingAmount(TimeLock storage lock_, uint256 ts)
    private
    view
    returns (uint256)
  {
    if (lock_.end != 0) {
      if (ts >= lock_.end) {
        return lock_.totalAmount.sub(lock_.providedAmount);
      } else {
        return
          lock_.pendingAmount.add(
            lock_.totalAmount.mul(ts.sub(lock_.last)).div(MONTHLY_REWARD)
          );
      }
    } else {
      return lock_.pendingAmount;
    }
  }

  /**
   * @dev Verify that we never exceed the token supply from tokenomics and fees
   */
  function _verifyRewardsProvided() private view {
    uint256 externalSupply = rewardHandler.getBoosterRewards();

    require(
      rewardsProvided <= externalSupply.add(MAX_TOKENOMICS_REWARDS),
      'B: Cap reached'
    );
  }
}

