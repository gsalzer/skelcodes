// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "solowei/contracts/TwoStageOwnable.sol";

contract Staking is TwoStageOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct StakeData {
        uint256 amount;
        uint256 rewards;
        uint256 withdrawn;
        uint256 startsAt;
    }

    uint256 public minStakeAmount;
    uint256 public revenue;
    IERC20 public stakingToken;

    uint256 private _freeSize;
    uint256 private _intervalsCount;
    uint256 private _intervalDuration;
    uint256 private _rewardPool;
    uint256 private _size;
    uint256 private _totalStaked;
    mapping(address => StakeData[]) private _stakedInformation;

    function getTimestamp() internal virtual view returns (uint256) {
        return block.timestamp;
    }

    function freeSize() public view returns (uint256) {
        return _freeSize;
    }

    function intervalsCount() public view returns (uint256) {
        return _intervalsCount;
    }

    function intervalDuration() public view returns (uint256) {
        return _intervalDuration;
    }

    function requiredRewards() public view returns (uint256) {
        return _calculateRewards(_totalStaked);
    }

    function rewardPool() public view returns (uint256) {
        return _rewardPool;
    }

    function size() public view returns (uint256) {
        return _size;
    }

    function totalStaked() public view returns (uint256) {
        return _totalStaked;
    }

    function availableToWithdraw(address account, uint256 id) public view returns (uint256 amountToWithdraw) {
        StakeData storage stakeData = _getStake(account, id);
        uint256 pastIntervalsCount = getTimestamp().sub(stakeData.startsAt).div(_intervalDuration);
        uint256 intervalRewards = stakeData.rewards.div(_intervalsCount);
        amountToWithdraw = pastIntervalsCount.mul(intervalRewards);
        if (stakeData.rewards < amountToWithdraw) {
            amountToWithdraw = stakeData.rewards;
        }
        amountToWithdraw = amountToWithdraw.sub(stakeData.withdrawn);
    }

    function getStake(address account, uint256 id) public view returns (StakeData memory) {
        return _getStake(account, id);
    }

    function getStakesCount(address account) public view returns (uint256) {
        return _stakedInformation[account].length;
    }

    function getStakes(
        address account,
        uint256 offset,
        uint256 limit
    ) public view returns (StakeData[] memory stakeData) {
        StakeData[] storage stakedInformation = _stakedInformation[account];
        uint256 stakedInformationLength = stakedInformation.length;
        uint256 to = offset.add(limit);
        if (stakedInformationLength < to) to = stakedInformationLength;
        stakeData = new StakeData[](to - offset);
        for (uint256 i = offset; i < to; i++) {
            stakeData[i - offset] = stakedInformation[stakedInformationLength - i - 1];
        }
    }

    event MinStakeAmountUpdated(address indexed owner, uint256 value);
    event Staked(address indexed account, uint256 stakeId, uint256 amount);
    event RewardPoolDecreased(address indexed owner, uint256 amount);
    event RewardPoolIncreased(address indexed owner, uint256 amount);
    event Withdrawn(address indexed account, uint256 stakeId, uint256 amount);

    constructor(
        address owner_,
        IERC20 stakingToken_,
        uint256 revenue_,
        uint256 intervalsCount_,
        uint256 intervalDuration_,
        uint256 size_
    ) public TwoStageOwnable(owner_) {
        require(revenue_ > 0, "Revenue not positive");
        require(intervalsCount_ > 0, "IntervalsCount not positive");
        require(intervalDuration_ > 0, "IntervalDuration not positive");
        require(size_ > 0, "Size not positive");
        stakingToken = stakingToken_;
        revenue = revenue_;
        _intervalsCount = intervalsCount_;
        _intervalDuration = intervalDuration_; //* 1 days;
        _size = size_;
        _freeSize = size_;
    }

    function decreaseRewardPool(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        uint256 requiredRewards_ = requiredRewards();
        require(_rewardPool > requiredRewards_, "No tokens to decrease");
        require(amount <= _rewardPool.sub(requiredRewards_), "Not enough amount");
        stakingToken.safeTransfer(caller, amount);
        _rewardPool = _rewardPool.sub(amount);
        emit RewardPoolDecreased(caller, amount);
        return true;
    }

    function increaseRewardPool(uint256 amount) external onlyOwner onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        stakingToken.safeTransferFrom(caller, address(this), amount);
        _rewardPool = _rewardPool.add(amount);
        emit RewardPoolIncreased(caller, amount);
        return true;
    }

    function setMinStakeAmount(uint256 value) external onlyOwner returns (bool) {
        minStakeAmount = value;
        emit MinStakeAmountUpdated(msg.sender, value);
        return true;
    }

    function stake(uint256 amount) external onlyPositiveAmount(amount) returns (bool) {
        require(amount >= minStakeAmount, "Amount lt minimum stake");
        require(amount <= _freeSize, "Amount gt free size");
        _freeSize = _freeSize.sub(amount);
        uint256 rewards = _calculateRewards(amount);
        require(rewards <= _rewardPool.sub(requiredRewards()), "Not enough rewards");
        address caller = msg.sender;
        uint256 stakeId = _stakedInformation[caller].length;
        _totalStaked = _totalStaked.add(amount);
        _stakedInformation[caller].push();
        StakeData storage stake_ = _stakedInformation[caller][stakeId];
        stake_.amount = amount;
        stake_.rewards = rewards.add(amount);
        stake_.startsAt = getTimestamp();
        stakingToken.safeTransferFrom(caller, address(this), amount);
        emit Staked(caller, stakeId, amount);
        return true;
    }

    function withdraw(uint256 id, uint256 amount) external onlyPositiveAmount(amount) returns (bool) {
        address caller = msg.sender;
        require(amount <= availableToWithdraw(caller, id), "Not enough available tokens");
        uint256 stakeSubAmount = amount.mul(100).div(revenue.add(100));
        _rewardPool = _rewardPool.sub(amount.sub(stakeSubAmount));
        _totalStaked = _totalStaked.sub(stakeSubAmount);
        StakeData storage stakeData = _stakedInformation[caller][id];
        stakeData.withdrawn = stakeData.withdrawn.add(amount);
        stakingToken.safeTransfer(caller, amount);
        emit Withdrawn(caller, id, amount);
        return true;
    }

    function _calculateRewards(uint256 amount) internal view returns (uint256) {
        return amount.mul(revenue).div(100);
    }

    function _getStake(address account, uint256 id) internal view returns (StakeData storage) {
        require(id < _stakedInformation[account].length, "Invalid stake id");
        return _stakedInformation[account][id];
    }

    modifier onlyPositiveAmount(uint256 amount) {
        require(amount > 0, "Amount not positive");
        _;
    }
}

