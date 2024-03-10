pragma solidity ^0.5.0;

import "./Math.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract DevRewards is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private kani = IERC20(0x790aCe920bAF3af2b773D4556A69490e077F6B4A);
    uint256 private rewards = 500000*1e18;
    uint256 private rewarded;
    uint256 private startTime = 1599321600;

    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);

    function availableRewards() public view returns (uint256) {
        if (startTime <= 0) return 0;
        uint day = Math.min(block.timestamp.sub(startTime).div(86400), 100);
        return day.mul(rewards).div(100).sub(rewarded);
    }

    function getReward(address account, uint256 amount) public onlyOwner{
        require(startTime > 0, "not start");
        require(amount > 0, "cannot get 0");
        require(availableRewards() >= amount, "available not enough");
        rewarded = rewarded.add(amount);
        kani.safeTransfer(account, amount);
        emit RewardPaid(account, amount);
    }

    function notifyRewardAmount(uint256 reward) public onlyOwner {
        require(reward > 0, "cannot reward 0");
        require(reward == rewards, "reward amount error");
        kani.mint(address(this),reward);
        emit RewardAdded(reward);
    }
}
