/*
 * Copyright (C) 2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity 0.7.6;

import '../../0xerc1155/access/AccessControl.sol';

import '../investment/interfaces/IRewardHandler.sol';

import './interfaces/IBooster.sol';

contract BoosterMain is IBooster, AccessControl {
  //////////////////////////////////////////////////////////////////////////////
  // Constants
  //////////////////////////////////////////////////////////////////////////////

  bytes32 public constant CONTROLLER_ROLE = bytes32('CONTROLLER');
  bytes32 public constant MIGRATOR_ROLE = bytes32('MIGRATOR');

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  // The rewardHandler to distribute rewards
  address public override rewardHandler;

  // The SFT contract to validate recipients
  address public override sftHolder;

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
  function initialize(address admin) external {
    // Validate parameters
    require(
      getRoleMemberCount(DEFAULT_ADMIN_ROLE) == 0,
      'B: Already initialized'
    );

    // For administrative calls
    _setupRole(DEFAULT_ADMIN_ROLE, admin);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IBooster}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IBooster-getRewardInfo}
   */
  function getRewardInfo(
    uint256[] memory /*tokenIds*/
  )
    external
    pure
    override
    returns (
      uint256[] memory locked,
      uint256[] memory pending,
      uint256[] memory apr,
      uint256[] memory secsLeft
    )
  {
    locked = new uint256[](0);
    pending = locked;
    apr = locked;
    secsLeft = locked;
  }

  /**
   * @dev See {IBooster-distributeFromFarm}
   */
  function distributeFromFarm(
    address, /* farm */
    address recipient,
    uint256 amount,
    uint32 fee
  ) external override onlyController {
    IRewardHandler(rewardHandler).distribute2(recipient, amount, fee);
  }

  /**
   * @dev See {IBooster-lock}
   */
  function lock(
    address, /* recipient */
    uint256 /* lockPeriod */
  ) external pure override {
    revert('B: Not implemented');
  }

  /**
   * @dev See {IBooster-claimRewards}
   */
  function claimRewards(uint256 sftTokenId, bool reLock)
    external
    pure
    override
  {}

  /**
   * @dev See {IBooster-migrateCreatePool}
   */
  function migrateCreatePool(
    uint256, /* tokenId*/
    bytes memory, /* data*/
    uint256 dataIndex
  ) external pure override returns (uint256) {
    return dataIndex;
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
   * @dev See {IBooster-setSftHolder}
   */
  function setSftHolder(address sftHolder_) external override onlyAdmin {
    // Validate input
    require(sftHolder_ != address(0), 'B: Invalid sftHolder');

    // Update state
    sftHolder = sftHolder_;
  }

  /**
   * @dev See {IBooster-setRewardHandler}
   */
  function setRewardHandler(address rewardHandler_)
    external
    override
    onlyAdmin
  {
    require(rewardHandler_ != address(0), 'B: Invalid rewardHandler');

    // Update state
    rewardHandler = rewardHandler_;
  }
}

