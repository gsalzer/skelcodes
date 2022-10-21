// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { LS1Types } from '../lib/LS1Types.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { LS1Borrowing } from './LS1Borrowing.sol';

/**
 * @title LS1Admin
 * @author dYdX
 *
 * @dev Admin-only functions.
 */
abstract contract LS1Admin is
  LS1Borrowing
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ External Functions ============

  /**
   * @notice Set the parameters defining the function from timestamp to epoch number.
   *
   *  The formula used is `n = floor((t - b) / a)` where:
   *    - `n` is the epoch number
   *    - `t` is the timestamp (in seconds)
   *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
   *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
   *
   *  Reverts if epoch zero already started, and the new parameters would change the current epoch.
   *  Reverts if epoch zero has not started, but would have had started under the new parameters.
   *  Reverts if the new interval is less than twice the blackout window.
   *
   * @param  interval  The length `a` of an epoch, in seconds.
   * @param  offset    The offset `b`, i.e. the start of epoch zero, in seconds.
   */
  function setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    if (!hasEpochZeroStarted()) {
      require(block.timestamp < offset, 'LS1Admin: Started epoch zero');
      _setEpochParameters(interval, offset);
      return;
    }

    // Require that we are not currently in a blackout window.
    require(
      !inBlackoutWindow(),
      'LS1Admin: Blackout window'
    );

    // We must settle the total active balance to ensure the index is recorded at the epoch
    // boundary as needed, before we make any changes to the epoch formula.
    _settleTotalActiveBalance();

    // Update the epoch parameters. Require that the current epoch number is unchanged.
    uint256 originalCurrentEpoch = getCurrentEpoch();
    _setEpochParameters(interval, offset);
    uint256 newCurrentEpoch = getCurrentEpoch();
    require(originalCurrentEpoch == newCurrentEpoch, 'LS1Admin: Changed epochs');

    // Require that the new parameters don't put us in a blackout window.
    require(!inBlackoutWindow(), 'LS1Admin: End in blackout window');
  }

  /**
   * @notice Set the blackout window, during which one cannot request withdrawals of staked funds.
   */
  function setBlackoutWindow(
    uint256 blackoutWindow
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    require(
      !inBlackoutWindow(),
      'LS1Admin: Blackout window'
    );
    _setBlackoutWindow(blackoutWindow);

    // Require that the new parameters don't put us in a blackout window.
    require(!inBlackoutWindow(), 'LS1Admin: End in blackout window');
  }

  /**
   * @notice Set the emission rate of rewards.
   *
   * @param  emissionPerSecond  The new number of rewards tokens given out per second.
   */
  function setRewardsPerSecond(
    uint256 emissionPerSecond
  )
    external
    onlyRole(REWARDS_RATE_ROLE)
    nonReentrant
  {
    uint256 totalStaked = 0;
    if (hasEpochZeroStarted()) {
      // We must settle the total active balance to ensure the index is recorded at the epoch
      // boundary as needed, before we make any changes to the emission rate.
      totalStaked = _settleTotalActiveBalance();
    }
    _setRewardsPerSecond(emissionPerSecond, totalStaked);
  }

  /**
   * @notice Change the allocations of certain borrowers. Can be used to add and remove borrowers.
   *  Increases take effect in the next epoch, but decreases will restrict borrowing immediately.
   *  This function cannot be called during the blackout window.
   *
   * @param  borrowers       Array of borrower addresses.
   * @param  newAllocations  Array of new allocations per borrower, as hundredths of a percent.
   */
  function setBorrowerAllocations(
    address[] calldata borrowers,
    uint256[] calldata newAllocations
  )
    external
    onlyRole(BORROWER_ADMIN_ROLE)
    nonReentrant
  {
    require(borrowers.length == newAllocations.length, 'LS1Admin: Params length mismatch');
    require(
      !inBlackoutWindow(),
      'LS1Admin: Blackout window'
    );
    _setBorrowerAllocations(borrowers, newAllocations);
  }

  function setBorrowingRestriction(
    address borrower,
    bool isBorrowingRestricted
  )
    external
    onlyRole(BORROWER_ADMIN_ROLE)
    nonReentrant
  {
    _setBorrowingRestriction(borrower, isBorrowingRestricted);
  }
}

