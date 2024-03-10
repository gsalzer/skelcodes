/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

import 'contracts/src/investment/interfaces/IRewardHandler.sol';
import 'contracts/src/token/interfaces/IERC20WowsMintable.sol';
import 'contracts/src/utils/AddressBook.sol';
import 'contracts/src/utils/interfaces/IAddressRegistry.sol';

contract RewardHandler is AccessControl, IRewardHandler {
  using SafeMath for uint256;

  // Role granted to distribute funds
  bytes32 public constant REWARD_ROLE = 'reward_role';

  // The fee is distributed to 4 channels:
  // 0.15 team
  uint32 private constant FEE_TO_TEAM = 15 * 1e4;
  // 0.15 marketing
  uint32 private constant FEE_TO_MARKETING = 15 * 1e4;
  // 0.4 booster
  uint32 private constant FEE_TO_BOOSTER = 4 * 1e5;
  // 0.3 back to reward pool (remaining fee remains in contract)
  // uint32 private constant FEE_TO_REWARDPOOL = 3 * 1e5;

  // Minimal mint amount
  uint256 private _minimalMintAmount = 100 * 1e18;

  // Registry for addresses in the system
  IAddressRegistry private immutable _addressRegistry;

  // Amount to distribute?
  uint256 private _distributeAmount;

  /**
   * @dev Constructor
   *
   * @param addressRegistry The registry for addresses in the system
   */
  constructor(IAddressRegistry addressRegistry) {
    // Initialize parameters
    _addressRegistry = addressRegistry;

    // Initialize access
    address marketingWallet =
      addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Public API
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the minimal mint amount to save mint calls
   *
   * @param newAmount The new minimal amount before mint() is called
   */
  function setMinimalMintAmount(uint256 newAmount) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');

    // Update state
    _minimalMintAmount = newAmount;
  }

  /**
   * @dev Distribute _distributeAmount to internal targets
   */
  function distributeAll() external {
    _distribute();
  }

  /**
   * @dev Distribute _distributeAmount to internal targets, transfer all WOWS
   * to the new reward handler, and destroy this contract
   *
   * @param newRewardHandler The reward handler that succeeds this one
   * @param destroy True to destroy this contract, false to distribute without
   * destroying
   */
  function terminate(address newRewardHandler, bool destroy) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), 'Only admins');

    // Distribute remaining fees
    IERC20WowsMintable rewardToken = _distribute();

    // Transfer WOWS to the new rewardHandler
    uint256 amountRewards = rewardToken.balanceOf(address(this));
    if (amountRewards > 0)
      rewardToken.transfer(newRewardHandler, amountRewards);

    // Destroy contract
    if (destroy) selfdestruct(payable(address(this)));
  }

  /**
   * @dev Withdraw tokenAddress ERC20token to destiation
   * tokenAddress cannot be rewardToken.
   * TODO: provide the possibility to swap into WOWS
   *
   * @param tokenAddress the address of the token to transfer
   */
  function collectGarbage(address tokenAddress) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');
    address rewardToken =
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN);
    require(tokenAddress != address(rewardToken), 'rewardToken not allowed');

    // Transfer token to msg.sender
    uint256 amountToken = IERC20(tokenAddress).balanceOf(address(this));
    if (amountToken > 0)
      IERC20(tokenAddress).transfer(_msgSender(), amountToken);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IRewardHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IRewardHandler-distribute2}
   */
  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) public override {
    // Validate access
    require(hasRole(REWARD_ROLE, msg.sender), 'Only rewarders');

    // If amount is zero there's nothing to do
    if (amount == 0) return;

    IERC20WowsMintable rewardToken =
      IERC20WowsMintable(
        _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
      );

    // Calculate absolute fee
    uint256 absFee = amount.mul(fee).div(1e6);

    // Calculate amount to send to the recipient
    uint256 recipientAmount = amount.sub(absFee);

    // Update state with accumulated fee to be distributed
    _distributeAmount = _distributeAmount.add(absFee);

    if (recipientAmount > 0) {
      // Check how much we have to mint
      uint256 balance = rewardToken.balanceOf(address(this));

      // Mint to this contract
      if (balance < recipientAmount) {
        uint256 mintAmount =
          recipientAmount > _minimalMintAmount
            ? recipientAmount
            : _minimalMintAmount;
        rewardToken.mint(address(this), mintAmount);
      }

      // Now send rewards to the user
      rewardToken.transfer(recipient, recipientAmount);
    }
  }

  /**
   * @dev See {IRewardHandler-distribute}
   */
  function distribute(
    address recipient,
    uint256 amount,
    uint32 fee,
    uint32,
    uint32,
    uint32,
    uint32
  ) external override {
    // Forward to new distribution function
    distribute2(recipient, amount, fee);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Internal details
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Distribute the accumulated fees
   *
   * @return The WOWS token
   */
  function _distribute() internal returns (IERC20WowsMintable) {
    // Validate state
    require(_distributeAmount > 0, 'nothing to distribute');

    IERC20WowsMintable rewardToken =
      IERC20WowsMintable(
        _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
      );

    // Load addresses
    address marketingWallet =
      _addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);
    address teamWallet =
      _addressRegistry.getRegistryEntry(AddressBook.TEAM_WALLET);
    address booster =
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_BOOSTER);

    // Load state
    uint256 distributeAmount = _distributeAmount;

    // Update state
    _distributeAmount = 0;

    // Check how much / if we have to mint
    uint256 balance = rewardToken.balanceOf(address(this));
    if (balance < distributeAmount)
      rewardToken.mint(address(this), distributeAmount.sub(balance));

    // Distribute the fee
    rewardToken.transfer(
      teamWallet,
      distributeAmount.mul(FEE_TO_TEAM).div(1e6)
    );
    rewardToken.transfer(
      marketingWallet,
      distributeAmount.mul(FEE_TO_MARKETING).div(1e6)
    );
    rewardToken.transfer(
      booster,
      distributeAmount.mul(FEE_TO_BOOSTER).div(1e6)
    );

    return rewardToken;
  }
}

