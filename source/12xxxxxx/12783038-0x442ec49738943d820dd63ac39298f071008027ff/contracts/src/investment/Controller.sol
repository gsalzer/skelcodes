/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/Context.sol';

import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IController.sol';
import './interfaces/IFarm.sol';
import './interfaces/IRewardHandler.sol';

contract Controller is IController, Context, Ownable {
  using SafeMath for uint256;

  //////////////////////////////////////////////////////////////////////////////
  // State
  //////////////////////////////////////////////////////////////////////////////

  // We need the previous controller for calculation of pending rewards
  address public previousController;

  // Our rewardHandler which distributes rewards
  IRewardHandler public rewardHandler;

  // The address which is alowed to call service functions
  address public worker;

  address private farmHead;
  struct Farm {
    address nextFarm;
    uint256 farmStartedAtBlock;
    uint256 farmEndedAtBlock;
    uint256 rewardCap;
    uint256 rewardProvided;
    uint256 rewardPerDuration;
    uint32 rewardFee;
    bool paused;
    bool active;
  }

  mapping(address => Farm) public farms;

  //////////////////////////////////////////////////////////////////////////////
  // Events
  //////////////////////////////////////////////////////////////////////////////

  event FarmRegistered(address indexed farm);

  event FarmUpdated(address indexed farm);

  event FarmDisabled(address indexed farm);

  event FarmPaused(address indexed farm, bool pause);

  event FarmTransfered(address indexed farm, address indexed to);

  event Rebalanced(address indexed farm);

  event Refueled(address indexed farm, uint256 amount);

  //////////////////////////////////////////////////////////////////////////////
  // Modifiers
  //////////////////////////////////////////////////////////////////////////////

  modifier onlyWorker {
    require(_msgSender() == worker, 'not worker');
    _;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Initialization
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev rewardHandler is the instance which finally stores the reward token
   * and distributes them to the different recipients
   *
   * @param _addressRegistry IAdressRegistry to get system addresses
   * @param _rewardHandler Handler of reward distribution
   * @param _previousController The previous controller
   */
  constructor(
    IAddressRegistry _addressRegistry,
    address _rewardHandler,
    address _previousController
  ) {
    // Initialize state
    setRewardHandler(_rewardHandler);
    previousController = _previousController;

    // Initialize {Ownable}
    address _marketingWallet =
      _addressRegistry.getRegistryEntry(AddressBook.MARKETING_WALLET);
    transferOwnership(_marketingWallet);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Routing
  //////////////////////////////////////////////////////////////////////////////

  function setRewardHandler(address _rewardHandler) public onlyOwner {
    rewardHandler = IRewardHandler(_rewardHandler);
  }

  function setWorker(address _worker) external onlyOwner {
    worker = _worker;
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation of {IController}
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev See {IController-onDeposit}
   */
  function onDeposit(
    uint256 /* amount*/
  ) external view override returns (uint256 fee) {
    // Load state
    Farm storage farm = farms[_msgSender()];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Caller not a farm');
    require(farm.farmEndedAtBlock == 0, 'Farm closed');
    require(!farm.paused, 'Farm paused');

    return 0;
  }

  /**
   * @dev See {IController-onDeposit}
   */
  function onWithdraw(
    uint256 /* amount*/
  ) external view override returns (uint256 fee) {
    // Validate state
    require(!farms[_msgSender()].paused, 'Farm paused');

    return 0;
  }

  /**
   * @dev See {IController-payOutRewards}
   */
  function payOutRewards(address recipient, uint256 amount) external override {
    // Load state
    Farm storage farm = farms[_msgSender()];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Caller not a farm');
    require(recipient != address(0), 'Recipient 0 address');
    require(!farm.paused, 'Farm paused');
    require(
      amount.add(farm.rewardProvided) <= farm.rewardCap,
      'Reward cap reached'
    );

    // Update state
    rewardHandler.distribute2(recipient, amount, farm.rewardFee);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Farm management
  //////////////////////////////////////////////////////////////////////////////

  /**
   * @dev registerFarm can be called from outside (for new Farms deployed with
   * this controller) or from transferFarm() call
   *
   * Contracts are active from the time of registering, but to provide rewards,
   * refuelFarms must be called (for new Farms / due Farms).
   *
   * Use this function also for updating reward parameters and / or fee.
   * _rewardProvided should be left 0, it is mainly used if a farm is
   * transferred.
   *
   * @param _farmAddress Contract address of farm
   * @param _rewardCap Maximum amount of tokens rewardable
   * @param _rewardPerDuration Refuel amount of tokens, duration is fixed in
   * farm contract
   * @param _rewardProvided Already provided rewards for this farm, should be 0
   * for external calls
   * @param _rewardFee Fee we take from the reward and distribute through
   * components (1e6 factor)
   */
  function registerFarm(
    address _farmAddress,
    uint256 _rewardCap,
    uint256 _rewardPerDuration,
    uint256 _rewardProvided,
    uint32 _rewardFee
  ) external {
    // Validate access
    require(
      _msgSender() == owner() || _msgSender() == previousController,
      'Not allowed'
    );

    // Validate parameters
    require(_farmAddress != address(0), 'Invalid farm (0)');
    require(IFarm(_farmAddress).controller() == this, 'Invalid farm (C)');

    // Farm existent, add new reward logic
    Farm storage farm = farms[_farmAddress];
    if (farm.farmStartedAtBlock > 0) {
      // Re-enable farm if disabled
      farm.farmEndedAtBlock = 0;
      farm.paused = false;
      farm.active = true;
      farm.rewardCap = _rewardCap;
      farm.rewardFee = _rewardFee;
      farm.rewardPerDuration = _rewardPerDuration;
      if (_rewardProvided > 0) farm.rewardProvided = _rewardProvided;

      // Dispatch event
      emit FarmUpdated(_farmAddress);
    }
    // We have a new farm
    else {
      // If we have one with same name, deactivate old one
      bytes32 farmName =
        keccak256(abi.encodePacked(IFarm(_farmAddress).farmName()));
      address searchAddress = farmHead;
      while (
        searchAddress != address(0) &&
        farmName != keccak256(abi.encodePacked(IFarm(searchAddress).farmName()))
      ) searchAddress = farms[searchAddress].nextFarm;

      // If found (update), disable existing farm
      if (searchAddress != address(0)) {
        farms[searchAddress].farmEndedAtBlock = block.number;
        _rewardProvided = farms[searchAddress].rewardProvided;
      }

      // Insert the new Farm
      farm.nextFarm = farmHead;
      farm.farmStartedAtBlock = block.number;
      farm.farmEndedAtBlock = 0;
      farm.rewardCap = _rewardCap;
      farm.rewardProvided = _rewardProvided;
      farm.rewardPerDuration = _rewardPerDuration;
      farm.rewardFee = _rewardFee;
      farm.paused = false;
      farm.active = true;
      farmHead = _farmAddress;

      // Dispatch event
      emit FarmRegistered(_farmAddress);
    }
  }

  /**
   * @dev Note that disabled farms can only be enabled again by calling
   * registerFarm() with new parameters
   *
   * This function is meant to finally end a farm.
   *
   * @param _farmAddress Contract address of farm to disable
   */
  function disableFarm(address _farmAddress) external onlyOwner {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Not a farm');

    // Update state
    farm.farmEndedAtBlock = block.number;

    // Dispatch event
    emit FarmDisabled(_farmAddress);

    _checkActive(farm);
  }

  /**
   * @dev This is an emergency pause, which should be called in case of serious
   * issues.
   *
   * Deposit / withdraw and rewards are disabled while pause is set to true.
   *
   * @param _farmAddress Contract address of farm to disable
   * @param _pause To enable / disable a farm
   */
  function pauseFarm(address _farmAddress, bool _pause) external onlyOwner {
    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Not a farm');

    // Update state
    farm.paused = _pause;

    // Dispatch event
    emit FarmPaused(_farmAddress, _pause);

    _checkActive(farm);
  }

  function transferFarm(address _farmAddress, address _newController)
    public
    onlyOwner
  {
    // Validate parameters
    require(_newController != address(0), 'newController = 0');
    require(_newController != address(this), 'newController = this');

    // Load state
    Farm storage farm = farms[_farmAddress];

    // Validate state
    require(farm.farmStartedAtBlock > 0, 'Farm not registered');

    // Update state
    IFarm(_farmAddress).setController(_newController);

    // Register this farm in the new controller
    Controller(_newController).registerFarm(
      _farmAddress,
      farm.rewardCap,
      farm.rewardPerDuration,
      farm.rewardProvided,
      farm.rewardFee
    );

    // Remove this farm from controller
    if (_farmAddress == farmHead) {
      farmHead = farm.nextFarm;
    } else {
      address searchAddress = farmHead;
      while (farms[searchAddress].nextFarm != _farmAddress)
        searchAddress = farms[searchAddress].nextFarm;
      farms[searchAddress].nextFarm = farm.nextFarm;
    }

    delete (farms[_farmAddress]);

    // Dispatch event
    emit FarmTransfered(_farmAddress, _newController);
  }

  function transferAllFarms(address _newController) external onlyOwner {
    while (farmHead != address(0)) {
      transferFarm(farmHead, _newController);
    }
  }

  function setFarmRewardDuration(address farmAddress, uint256 newDuration)
    external
    onlyOwner
  {
    require(IFarm(farmAddress).controller() == this, 'Invalid farm (C)');
    IFarm(farmAddress).setRewardsDuration(newDuration);
  }

  //////////////////////////////////////////////////////////////////////////////
  // Utility functions
  //////////////////////////////////////////////////////////////////////////////

  function rebalance() external onlyWorker {
    // Update state
    address iterAddress = farmHead;
    while (iterAddress != address(0)) {
      if (farms[iterAddress].active) {
        IFarm(iterAddress).rebalance();
      }
      iterAddress = farms[iterAddress].nextFarm;
    }

    // Dispatch event
    emit Rebalanced(iterAddress);
  }

  function refuelFarms() external onlyWorker {
    address iterAddress = farmHead;
    bool oneRefueled = false;
    while (iterAddress != address(0)) {
      // Refuel if farm end is one day ahead
      Farm storage farm = farms[iterAddress];
      if (
        farm.active &&
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + 86400 >= IFarm(iterAddress).periodFinish()
      ) {
        // Update state
        IFarm(iterAddress).notifyRewardAmount(farm.rewardPerDuration);
        farm.rewardProvided = farm.rewardProvided.add(farm.rewardPerDuration);
        oneRefueled = true;

        // Dispatch event
        emit Refueled(iterAddress, farm.rewardPerDuration);
      }
      iterAddress = farm.nextFarm;
    }
    require(oneRefueled, 'NOP');
  }

  //////////////////////////////////////////////////////////////////////////////
  // Implementation details
  //////////////////////////////////////////////////////////////////////////////

  function _checkActive(Farm storage farm) internal {
    farm.active = !(farm.paused || farm.farmEndedAtBlock > 0);
  }
}

