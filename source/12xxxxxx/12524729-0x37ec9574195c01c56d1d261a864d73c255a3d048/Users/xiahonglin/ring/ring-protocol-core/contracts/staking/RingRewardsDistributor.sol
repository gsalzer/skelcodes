// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma experimental ABIEncoderV2;

import "../refs/CoreRef.sol";
import "../utils/Timed.sol";
import "./IRewardsDistributor.sol";
import "../external/Decimal.sol";
import { SafeMath } from  "@openzeppelin/contracts/math/SafeMath.sol";

/// @title Distributor for RING rewards to the staking contract
/// @author Ring Protocol
/// @notice distributes RING over time at a linearly decreasing rate
contract RingRewardsDistributor is IRewardsDistributor, CoreRef, Timed {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    uint256 public override distributedRewards;

    IStakingRewards public override stakingContract;

    uint256 public override lastDistributionTime;

    uint256 public override dripFrequency;

    uint256 public override incentiveAmount;

    constructor(
        address _core,
        address _stakingContract,
        uint256 _duration,
        uint256 _frequency,
        uint256 _incentiveAmount
    ) 
        CoreRef(_core) 
        Timed(_duration)
    {
        require(_duration >= _frequency, "RingRewardsDistributor: frequency exceeds duration");
        stakingContract = IStakingRewards(_stakingContract);
        dripFrequency = _frequency;
        incentiveAmount = _incentiveAmount;

        // solhint-disable-next-line not-rely-on-time
        lastDistributionTime = block.timestamp;

        _initTimed();
    }

    /// @notice sends the unlocked amount of RING to the stakingRewards contract
    /// @return amount of RING sent
    function drip() public override whenNotPaused nonContract returns(uint256) {
        require(isDripAvailable(), "RingRewardsDistributor: Not passed drip frequency");
        // solhint-disable-next-line not-rely-on-time
        lastDistributionTime = block.timestamp;

        uint amount = releasedReward();
        require(amount != 0, "RingRewardsDistributor: no rewards");
        distributedRewards = distributedRewards.add(amount);

        ring().transfer(address(stakingContract), amount);
        stakingContract.notifyRewardAmount(amount);

        _incentivize();
        
        emit Drip(msg.sender, amount);
        return amount;
    }

    /// @notice sends tokens back to governance treasury. Only callable by governance
    /// @param amount the amount of tokens to send back to treasury
    function governorWithdrawRing(uint256 amount) external override onlyGovernor {
        ring().transfer(address(core()), amount);
        emit RingWithdraw(amount);
    }

    /// @notice sends tokens back to governance treasury. Only callable by governance
    /// @param amount the amount of tokens to send back to treasury
    function governorRecover(address tokenAddress, address to, uint256 amount) external override onlyGovernor {
        stakingContract.recoverERC20(tokenAddress, to, amount);
    }

    /// @notice sets the drip frequency
    function setDripFrequency(uint256 _frequency) external override onlyGovernor {
        dripFrequency = _frequency;
        emit FrequencyUpdate(_frequency);
    }

    /// @notice sets the incentive amount for calling drip
    function setIncentiveAmount(uint256 _incentiveAmount) external override onlyGovernor {
        incentiveAmount = _incentiveAmount;
        emit IncentiveUpdate(_incentiveAmount);
    }

    /// @notice sets the staking contract to send RING rewards to
    function setStakingContract(address _stakingContract) external override onlyGovernor {
        stakingContract = IStakingRewards(_stakingContract);
        emit StakingContractUpdate(_stakingContract);
    }

    /// @notice returns the block timestamp when drip will next be available
    function nextDripAvailable() public view override returns (uint256) {
        return lastDistributionTime.add(dripFrequency);
    }

    /// @notice return true if the dripFrequency has passed since the last drip
    function isDripAvailable() public view override returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp >= nextDripAvailable();
    }

    /// @notice the total amount of rewards owned by contract and unlocked for release
    function releasedReward() public view override returns (uint256) {
        uint256 total = rewardBalance();
        uint256 unreleased = unreleasedReward();
        return total.sub(unreleased, "Pool: Released Reward underflow");
    }
    
    /// @notice the total amount of rewards distributed by the contract over entire period
    function totalReward() public view override returns (uint256) {
        return rewardBalance().add(distributedRewards);
    }

    /// @notice the total balance of rewards owned by contract, locked or unlocked
    function rewardBalance() public view override returns (uint256) {
        return ringBalance();
    }

    /// @notice the total amount of rewards owned by contract and locked
    function unreleasedReward() public view override returns (uint256) {
        if (isTimeEnded()) {
            return 0;
        }
        
        return
            _unreleasedReward(
                totalReward(),
                duration,
                timeSinceStart()
            );
    }

    // Represents the integral of 2R/d - 2R/d^2 x dx from t to d
    // Integral equals 2Rx/d - Rx^2/d^2
    // Evaluated at t = 2R*t/d (start) - R*t^2/d^2 (end)
    // Evaluated at d = 2R - R = R
    // Solution = R - (start - end) or equivalently end + R - start (latter more convenient to code)
    function _unreleasedReward(
        uint256 _totalReward,
        uint256 _duration,
        uint256 _time
    ) internal pure returns (uint256) {
        // 2R*t/d
        Decimal.D256 memory start =
            Decimal.ratio(_totalReward, _duration).mul(2).mul(_time);

        // R*t^2/d^2
        Decimal.D256 memory end =
            Decimal.ratio(_totalReward, _duration).div(_duration).mul(
                _time * _time
            );

        return end.add(_totalReward).sub(start).asUint256();
    }

    function _incentivize() internal ifMinterSelf {
        rusd().mint(msg.sender, incentiveAmount);
    }
}

