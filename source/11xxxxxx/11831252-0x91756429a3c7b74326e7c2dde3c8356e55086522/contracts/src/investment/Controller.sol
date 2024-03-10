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

import '../utils/AddressBook.sol';
import '../utils/interfaces/IAddressRegistry.sol';

import './interfaces/IController.sol';
import './interfaces/IFarm.sol';
import './interfaces/IRewardHandler.sol';

contract Controller is IController, Ownable, AddressBook {
  using SafeMath for uint256;

  /* ========== STATE VARIABLES ========== */

  // We need the previous controller for calculation of pending rewards
  address public previousController;
  // Our rewardHandler which distributes rewards
  IRewardHandler public rewardHandler;
  // The address which is alowed to call service functions
  address public worker;

  // The fee is distributed to 4 channels:
  // 0.15 team
  uint32 private constant FEE_TO_TEAM = 15 * 1e4;
  // 0.15 marketing
  uint32 private constant FEE_TO_MARKETING = 15 * 1e4;
  // 0.4 booster
  uint32 private constant FEE_TO_BOOSTER = 4 * 1e5;
  // 0.3 back to reward pool
  uint32 private constant FEE_TO_REWARDPOOL = 3 * 1e5;

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

  /* ========== MODIFIER ========== */

  modifier onlyWorker {
    require(_msgSender() == worker, 'not worker');
    _;
  }

  /* ========== EVENTS ========== */

  event FarmRegistered(address indexed farm);
  event FarmUpdated(address indexed farm);
  event FarmDisabled(address indexed farm);
  event FarmPaused(address indexed farm, bool pause);
  event FarmTransfered(address indexed farm, address indexed to);
  event Rebalanced(address indexed farm);
  event Refueled(address indexed farm, uint256 amount);

  /* ========== CONSTRUCTOR ========== */

  /**
   * @param _rewardHandler handler of reward distribution
   *
   * @dev rewardHandler is the instance which finally stores the reward token
   * and distributes them to the different recipients
   */
  constructor(
    IAddressRegistry _addressRegistry,
    address _rewardHandler,
    address _previousController
  ) {
    setRewardHandler(_rewardHandler);
    previousController = _previousController;

    address _marketingWallet =
      _addressRegistry.getRegistryEntry(MARKETING_WALLET);
    transferOwnership(_marketingWallet);
  }

  /* ========== ROUTING ========== */

  function setRewardHandler(address _rewardHandler) public onlyOwner {
    rewardHandler = IRewardHandler(_rewardHandler);
  }

  function setWorker(address _worker) external onlyOwner {
    worker = _worker;
  }

  /* ========== FARM CALLBACKS ========== */

  /**
   * @dev onDeposit() is used to control fees and accessibility instead having an
   * implementation in each farm contract
   *
   * Deposit is only allowed, if farm is open and not not paused.
   *
   * @param _amount #tokens the user wants to deposit
   *
   * @return fee returns the deposit fee (1e18 factor)
   */
  function onDeposit(uint256 _amount)
    external
    view
    override
    returns (uint256 fee)
  {
    Farm storage farm = farms[msg.sender];
    require(farm.farmStartedAtBlock > 0, 'caller not a farm');
    require(farm.farmEndedAtBlock == 0, 'farm closed');
    require(!farm.paused, 'farm paused');
    _amount;
    return 0;
  }

  /**
   * @dev onWithdraw() is used to control fees and accessibility instead having
   * an implementation in each farm contract
   *
   * Withdraw is only allowed, if farm is not paused.
   *
   * @param _amount #tokens the user wants to withdraw
   *
   * @return fee returns the withdraw fee (1e18 factor)
   */
  function onWithdraw(uint256 _amount)
    external
    view
    override
    returns (uint256 fee)
  {
    require(!farms[msg.sender].paused, 'farm paused');
    _amount;
    return 0;
  }

  function payOutRewards(address recipient, uint256 amount) external override {
    Farm storage farm = farms[msg.sender];
    require(farm.farmStartedAtBlock > 0, 'caller not a farm');
    require(recipient != address(0), 'recipient 0 address');
    require(!farm.paused, 'farm paused');
    require(
      amount.add(farm.rewardProvided) <= farm.rewardCap,
      'rewardCap reached'
    );

    rewardHandler.distribute(
      recipient,
      amount,
      farm.rewardFee,
      FEE_TO_TEAM,
      FEE_TO_MARKETING,
      FEE_TO_BOOSTER,
      FEE_TO_REWARDPOOL
    );
  }

  /* ========== FARM MANAGMENT ========== */

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
   * @param _farmAddress contract address of farm
   * @param _rewardCap max. amount of tokens rewardable
   * @param _rewardPerDuration refuel amount of tokens, duration is fixed in farm contract
   * @param _rewardProvided already provided rewards for this farm, should be 0 for external calls
   * @param _rewardFee fee we take from the reward and distribute through components (1e6 factor)
   */
  function registerFarm(
    address _farmAddress,
    uint256 _rewardCap,
    uint256 _rewardPerDuration,
    uint256 _rewardProvided,
    uint32 _rewardFee
  ) external {
    require(
      msg.sender == owner() || msg.sender == previousController,
      'not allowed'
    );
    require(_farmAddress != address(0), 'invalid farm');

    // Farm existent, add new reward logic
    Farm storage farm = farms[_farmAddress];
    if (farm.farmStartedAtBlock > 0) {
      // Re-enable farm if disabled
      farm.farmEndedAtBlock = 0;
      farm.paused = false;
      farm.active = true;
      farm.rewardCap = _rewardCap;
      farm.rewardFee = _rewardFee;
      if (_rewardProvided > 0) farm.rewardProvided = _rewardProvided;
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
      emit FarmRegistered(_farmAddress);
    }
  }

  /**
   * @dev note that disabled farm can only be enabled again by calling
   * registerFarm() with new parameters
   *
   * This function is meant to finally end a farm.
   *
   * @param _farmAddress contract address of farm to disable
   */
  function disableFarm(address _farmAddress) external onlyOwner {
    Farm storage farm = farms[_farmAddress];
    require(farm.farmStartedAtBlock > 0, 'not a farm');

    farm.farmEndedAtBlock = block.number;
    emit FarmDisabled(_farmAddress);
    _checkActive(farm);
  }

  /**
   * @dev This is an emergency pause, which should be called in case of serious
   * issues.
   *
   * Deposit / withdraw and rewards are disabled while pause is set to true.
   *
   * @param _farmAddress contract address of farm to disable
   * @param _pause to enable / disable a farm
   */
  function pauseFarm(address _farmAddress, bool _pause) external onlyOwner {
    Farm storage farm = farms[_farmAddress];
    require(farm.farmStartedAtBlock > 0, 'not a farm');

    farm.paused = _pause;
    emit FarmPaused(_farmAddress, _pause);
    _checkActive(farm);
  }

  function transferFarm(address _farmAddress, address _newController)
    external
    onlyOwner
  {
    Farm storage farm = farms[_farmAddress];
    require(farm.farmStartedAtBlock > 0, 'farm not registered');
    require(_newController != address(0), 'newController = 0');
    require(_newController != address(this), 'newController = this');

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
    emit FarmTransfered(_farmAddress, _newController);
  }

  /* ========== UTILITY FUNCTIONS ========== */

  function rebalance() external onlyWorker {
    address iterAddress = farmHead;
    while (iterAddress != address(0)) {
      if (farms[iterAddress].active) {
        IFarm(iterAddress).rebalance();
      }
      iterAddress = farms[iterAddress].nextFarm;
    }
    emit Rebalanced(iterAddress);
  }

  function refuelFarms() external onlyWorker {
    address iterAddress = farmHead;
    while (iterAddress != address(0)) {
      // Refuel if farm end is one day ahead
      Farm storage farm = farms[iterAddress];
      if (
        farm.active &&
        // solhint-disable-next-line not-rely-on-time
        block.timestamp + 86400 >= IFarm(iterAddress).periodFinish()
      ) {
        IFarm(iterAddress).notifyRewardAmount(farm.rewardPerDuration);
        farm.rewardProvided = farm.rewardProvided.add(farm.rewardPerDuration);
        emit Refueled(iterAddress, farm.rewardPerDuration);
      }
      iterAddress = farm.nextFarm;
    }
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  function _checkActive(Farm storage farm) internal {
    farm.active = !(farm.paused || farm.farmEndedAtBlock > 0);
  }
}

