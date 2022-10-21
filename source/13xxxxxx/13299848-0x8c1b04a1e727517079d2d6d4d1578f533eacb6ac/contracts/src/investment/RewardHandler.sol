/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.7.0 <0.8.0;

import '../../0xerc1155/access/AccessControl.sol';
import '../../0xerc1155/utils/SafeMath.sol';
import '../../0xerc1155/utils/SafeERC20.sol';
import '../../0xerc1155/utils/Context.sol';

import '../../interfaces/uniswap/IUniswapV2Router02.sol';
import '../investment/interfaces/IRewardHandler.sol';
import '../polygon/interfaces/IChildTunnel.sol';
import '../token/interfaces/IERC20WowsMintable.sol';
import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

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

  // Admin account
  address private immutable _adminAccount;

  // Team Wallet
  address private immutable _teamWallet;

  // Team Wallet
  address private immutable _marketingWallet;

  // The WOWS reward token
  IERC20WowsMintable private immutable _rewardToken;

  // Booster
  address private immutable _booster;

  // Uniswap
  IUniswapV2Router02 private immutable _uniV2Router;

  // Amount to distribute
  uint256 private _distributeAmount = 0;

  // IChildTunnel for internal distribution
  IChildTunnel public childTunnel = IChildTunnel(address(0));

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Fired on construction
   */
  event Constructed(
    address adminAccount,
    address marketingWallet,
    address teamWallet,
    address rewardToken,
    address booster,
    address uniV2Router
  );

  /**
   * @dev Fired if we receive Ether
   */
  event Received(address, uint256);

  /**
   * @dev Fired on distribute (rewards -> recipient)
   */
  event RewardsDistributed(address indexed, uint256 amount, uint32 fee);

  /**
   * @dev Fired on distributeAll (collected fees -> internal)
   */
  event FeesDistributed(uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Modifier
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyAdmin() {
    // Validate admin access
    require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'Only admin');
    _;
  }

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
    _setupRole(
      DEFAULT_ADMIN_ROLE,
      addressRegistry.getRegistryEntry(AddressBook.ADMIN_ACCOUNT)
    );

    // Initialize state

    address adminAccount = addressRegistry.getRegistryEntry(
      AddressBook.ADMIN_ACCOUNT
    );
    address marketingWallet = addressRegistry.getRegistryEntry(
      AddressBook.MARKETING_WALLET
    );
    address teamWallet = addressRegistry.getRegistryEntry(
      AddressBook.TEAM_WALLET
    );
    address rewardToken = addressRegistry.getRegistryEntry(
      AddressBook.WOWS_TOKEN
    );
    address booster = addressRegistry.getRegistryEntry(
      AddressBook.WOWS_BOOSTER_PROXY
    );
    address uniV2Router = addressRegistry.getRegistryEntry(
      AddressBook.UNISWAP_V2_ROUTER02
    );

    _adminAccount = adminAccount;
    _marketingWallet = marketingWallet;
    _teamWallet = teamWallet;
    _rewardToken = IERC20WowsMintable(rewardToken);
    _booster = booster;
    _uniV2Router = IUniswapV2Router02(uniV2Router);

    emit Constructed(
      adminAccount,
      marketingWallet,
      teamWallet,
      rewardToken,
      booster,
      uniV2Router
    );
  }

  /**
   * @dev Set the childTunnel for reward bridging (child chain only)
   */
  function setChildTunnel(IChildTunnel childTunnel_) external onlyAdmin {
    require(address(childTunnel_) != address(0), 'Zero address');

    childTunnel = childTunnel_;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Public API
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev Set the minimal mint amount to save mint calls
   *
   * @param newAmount The new minimal amount before mint() is called
   */
  function setMinimalMintAmount(uint256 newAmount) external onlyAdmin {
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
  function terminate(address newRewardHandler, bool destroy)
    external
    onlyAdmin
  {
    // Validate parameters
    require(newRewardHandler != address(0), "Can't transfer to address 0");

    // Distribute remaining fees
    _distribute();

    // Transfer WOWS to the new rewardHandler
    uint256 amountRewards = _rewardToken.balanceOf(address(this));
    if (amountRewards > 0)
      _rewardToken.safeTransfer(newRewardHandler, amountRewards);

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
  function swapIntoRewardToken(address[] calldata route) external onlyAdmin {
    // Check for ETH swap (no route given)
    if (route.length == 0) {
      // Validate state
      uint256 amountETH = payable(address(this)).balance;
      require(amountETH > 0, 'Insufficient amount');

      address[] memory ethRoute = new address[](2);
      ethRoute[0] = _uniV2Router.WETH();
      ethRoute[1] = address(_rewardToken);

      // Disable high-impact Slither detector "arbitrary-send" here. Slither
      // recommends that programmers "Ensure that an arbitrary user cannot
      // withdraw unauthorized funds." We accomplish this by using access
      // control to prevent unauthorized modification of the destination.
      //
      // slither-disable-next-line arbitrary-send
      uint256[] memory amounts = _uniV2Router.swapExactETHForTokens{
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
        route[route.length - 1] == address(_rewardToken),
        'Route terminator != rewardToken'
      );

      // Validate state
      uint256 amountToken = IERC20(route[0]).balanceOf(address(this));
      require(amountToken > 0, 'Insufficient amount');

      uint256[] memory amounts = _uniV2Router.swapExactTokensForTokens(
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
    return
      _rewardToken.balanceOf(_booster).add(
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

    // Calculate absolute fee
    uint256 absFee = amount.mul(fee).div(1e6);

    // Calculate amount to send to the recipient
    uint256 recipientAmount = amount.sub(absFee);

    // Update state with accumulated fee to be distributed
    _distributeAmount = _distributeAmount.add(absFee);

    if (recipientAmount > 0) {
      // Check how much we have to mint
      uint256 balance = _rewardToken.balanceOf(address(this));

      // Mint to this contract
      if (balance < recipientAmount) {
        uint256 mintAmount = recipientAmount > _minimalMintAmount
          ? recipientAmount
          : _minimalMintAmount;
        if (address(childTunnel) != address(0))
          _rewardToken.safeTransferFrom(
            _adminAccount,
            address(this),
            mintAmount
          );
        else _rewardToken.mint(address(this), mintAmount);
      }

      // Now send rewards to the user
      _rewardToken.safeTransfer(recipient, recipientAmount);
    }
    // Emit event
    emit RewardsDistributed(recipient, amount, fee);
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
   */
  function _distribute() internal {
    if (_distributeAmount > 0) {
      // Load state
      uint256 distributeAmount = _distributeAmount;

      // Update state
      _distributeAmount = 0;

      // Check how much / if we have to mint
      uint256 balance = _rewardToken.balanceOf(address(this));
      if (balance < distributeAmount)
        _rewardToken.mint(address(this), distributeAmount.sub(balance));

      // Distribute the fee
      if (address(childTunnel) == address(0)) {
        _rewardToken.safeTransfer(
          _teamWallet,
          distributeAmount.mul(FEE_TO_TEAM).div(1e6)
        );

        _rewardToken.safeTransfer(
          _marketingWallet,
          distributeAmount.mul(FEE_TO_MARKETING).div(1e6)
        );
      } else {
        childTunnel.distribute(
          distributeAmount.mul(FEE_TO_MARKETING + FEE_TO_TEAM).div(1e6)
        );
      }

      _rewardToken.safeTransfer(
        _booster,
        distributeAmount.mul(FEE_TO_BOOSTER).div(1e6)
      );

      // Emit event
      emit FeesDistributed(distributeAmount);
    }
  }
}

