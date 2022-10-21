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
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../../interfaces/uniswap/IUniswapV2Router02.sol';
import '../../src/investment/interfaces/IRewardHandler.sol';
import '../../src/token/interfaces/IERC20WowsMintable.sol';
import '../../src/utils/AddressBook.sol';
import '../../src/utils/interfaces/IAddressRegistry.sol';

contract RewardHandler is Context, AccessControl, IRewardHandler {
  using SafeMath for uint256;
  using SafeERC20 for IERC20WowsMintable;

  //////////////////////////////////////////////////////////////////////////////
  // Roles
  //////////////////////////////////////////////////////////////////////////////

  // Role granted to distribute funds
  bytes32 public constant REWARD_ROLE = 'reward_role';

  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  // The fee is distributed to 4 channels:
  // 0.15 team
  uint32 private constant FEE_TO_TEAM = 15 * 1e4;
  // 0.15 marketing
  uint32 private constant FEE_TO_MARKETING = 15 * 1e4;
  // 0.4 booster
  uint32 private constant FEE_TO_BOOSTER = 4 * 1e5;
  // 0.3 back to reward pool (remaining fee remains in contract)
  // uint32 private constant FEE_TO_REWARDPOOL = 3 * 1e5;

  // Duration of one hour, in seconds
  uint32 private constant ONE_HOUR = 3600;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // Minimal mint amount
  uint256 private _minimalMintAmount = 100 * 1e18;

  // Registry for addresses in the system
  IAddressRegistry private immutable _addressRegistry;

  // Amount to distribute
  uint256 private _distributeAmount;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Fired if we receive Ether
   */
  event Received(address, uint256);

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Constructor
   *
   * @param addressRegistry The registry for addresses in the system
   */
  constructor(IAddressRegistry addressRegistry) {
    // Initialize access
    address marketingWallet = addressRegistry.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    _setupRole(DEFAULT_ADMIN_ROLE, marketingWallet);

    // Initialize state
    _addressRegistry = addressRegistry;
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
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    // Update state
    _minimalMintAmount = newAmount;
  }

  /**
   * @dev Distribute _distributeAmount to internal targets
   */
  function distributeAll() external {
    // Validate state
    require(_distributeAmount > 0, 'Nothing to distribute');

    _distribute();
  }

  /**
   * @dev Distribute _distributeAmount to internal targets, transfer all WOWS
   * to the new reward handler, and (optionally) destroy this contract
   *
   * @param newRewardHandler The reward handler that succeeds this one
   * @param destroy True to destroy this contract, false to distribute without
   * destroying
   */
  function terminate(address newRewardHandler, bool destroy) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    // Validate parameters
    require(newRewardHandler != address(0), "Can't transfer to address 0");

    // Distribute remaining fees
    IERC20WowsMintable rewardToken = _distribute();

    // Transfer WOWS to the new rewardHandler
    uint256 amountRewards = rewardToken.balanceOf(address(this));
    if (amountRewards > 0)
      rewardToken.safeTransfer(newRewardHandler, amountRewards);

    // Destroy contract
    if (destroy) {
      // Disable high-impact Slither detector "suicidal" here. Slither explains
      // that "RewardHandler.terminate() allows anyone to destruct the
      // contract", which is not the case due to validatation of the sender
      // having the {AccessControl-DEFAULT_ADMIN_ROLE} role.
      //
      // slither-disable-next-line suicidal
      selfdestruct(payable(newRewardHandler));
    }
  }

  /**
   * @dev Swap ETH or ERC20 token into rewardToken
   *
   * tokenAddress cannot be rewardToken.
   *
   * @param route Path containing ERC20 token addresses to swap route[0] into
   * reward tokens. The last address must be rewardToken address.
   */
  function swapIntoRewardToken(address[] calldata route) external {
    // Validate access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admins');

    address rewardToken = _addressRegistry.getRegistryEntry(
      AddressBook.WOWS_TOKEN
    );

    // Get the UniV2 Router
    IUniswapV2Router02 router = IUniswapV2Router02(
      _addressRegistry.getRegistryEntry(AddressBook.UNISWAP_V2_ROUTER02)
    );

    // Check for ETH swap (no route given)
    if (route.length == 0) {
      // Validate state
      uint256 amountETH = payable(address(this)).balance;
      require(amountETH > 0, 'Insufficient amount');

      address[] memory ethRoute = new address[](2);
      ethRoute[0] = router.WETH();
      ethRoute[1] = rewardToken;

      // Disable high-impact Slither detector "arbitrary-send" here. Slither
      // recommends that programmers "Ensure that an arbitrary user cannot
      // withdraw unauthorized funds." We accomplish this by using access
      // control to prevent unauthorized modification of the destination.
      //
      // slither-disable-next-line arbitrary-send
      uint256[] memory amounts = router.swapExactETHForTokens{
        value: amountETH
      }(
        0,
        ethRoute,
        address(this),
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + ONE_HOUR
      );

      // Update state
      _distributeAmount = _distributeAmount.add(amounts[1]);
    } else {
      // Validate parameters
      require(route.length >= 2, 'Invalid route');
      require(
        route[route.length - 1] == address(rewardToken),
        'Route terminator != rewardToken'
      );

      // Validate state
      uint256 amountToken = IERC20(route[0]).balanceOf(address(this));
      require(amountToken > 0, 'Insufficient amount');

      uint256[] memory amounts = router.swapExactTokensForTokens(
        amountToken,
        0,
        route,
        address(this),
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + ONE_HOUR
      );

      // Update state
      _distributeAmount = _distributeAmount.add(amounts[route.length - 1]);
    }
  }

  // We can receive ether and swap it later to rewardToken
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IRewardHandler}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IRewardHandler-getBoosterRewards}
   */
  function getBoosterRewards() external view override returns (uint256) {
    IERC20WowsMintable rewardToken = IERC20WowsMintable(
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
    );
    address booster = _addressRegistry.getRegistryEntry(
      AddressBook.WOWS_BOOSTER_PROXY
    );
    return
      rewardToken.balanceOf(booster).add(
        _distributeAmount.mul(FEE_TO_BOOSTER).div(1e6)
      );
  }

  /**
   * @dev See {IRewardHandler-distribute2}
   */
  function distribute2(
    address recipient,
    uint256 amount,
    uint32 fee
  ) public override {
    // Validate access
    require(hasRole(REWARD_ROLE, _msgSender()), 'Only rewarders');

    // Validate parameters
    require(recipient != address(0), 'Invalid recipient');

    // If amount is zero there's nothing to do
    if (amount == 0) return;

    IERC20WowsMintable rewardToken = IERC20WowsMintable(
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
        uint256 mintAmount = recipientAmount > _minimalMintAmount
          ? recipientAmount
          : _minimalMintAmount;
        rewardToken.mint(address(this), mintAmount);
      }

      // Now send rewards to the user
      rewardToken.safeTransfer(recipient, recipientAmount);
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
   * @return The WOWS token address
   */
  function _distribute() internal returns (IERC20WowsMintable) {
    IERC20WowsMintable rewardToken = IERC20WowsMintable(
      _addressRegistry.getRegistryEntry(AddressBook.WOWS_TOKEN)
    );

    if (_distributeAmount > 0) {
      // Load addresses
      address marketingWallet = _addressRegistry.getRegistryEntry(
        AddressBook.MARKETING_WALLET
      );
      address teamWallet = _addressRegistry.getRegistryEntry(
        AddressBook.TEAM_WALLET
      );
      address booster = _addressRegistry.getRegistryEntry(
        AddressBook.WOWS_BOOSTER_PROXY
      );

      // Load state
      uint256 distributeAmount = _distributeAmount;

      // Update state
      _distributeAmount = 0;

      // Check how much / if we have to mint
      uint256 balance = rewardToken.balanceOf(address(this));
      if (balance < distributeAmount)
        rewardToken.mint(address(this), distributeAmount.sub(balance));

      // Distribute the fee
      rewardToken.safeTransfer(
        teamWallet,
        distributeAmount.mul(FEE_TO_TEAM).div(1e6)
      );
      rewardToken.safeTransfer(
        marketingWallet,
        distributeAmount.mul(FEE_TO_MARKETING).div(1e6)
      );
      rewardToken.safeTransfer(
        booster,
        distributeAmount.mul(FEE_TO_BOOSTER).div(1e6)
      );
    }
    return rewardToken;
  }
}

