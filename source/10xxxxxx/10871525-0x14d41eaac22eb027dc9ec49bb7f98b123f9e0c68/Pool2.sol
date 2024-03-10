pragma solidity ^0.5.0;

import "./Math.sol";
import "./SafeERC20.sol";
import "./IRewardDistributionRecipient.sol";

contract Govern is IERC20 {
    function make_profit(uint256 amount) external returns (bool);
}

library SafeGovern {
    using SafeMath for uint256;
    using Address for address;

    function safeMakeProfit(Govern token, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.make_profit.selector, value));
    }

    function callOptionalReturn(Govern token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public bpt = IERC20(0x8B2E66C3B277b2086a976d053f1762119A92D280);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        bpt.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        bpt.safeTransfer(msg.sender, amount);
    }
}

contract KaniRewards is LPTokenWrapper, IRewardDistributionRecipient {
    using SafeGovern for Govern;

    IERC20 public kani = IERC20(0x790aCe920bAF3af2b773D4556A69490e077F6B4A);
    uint256 public constant DURATION = 7 days;
    address govern = 0x3a8Ff8b9DE3429EA84DFC8e8f13072C6838d51aF;

    uint256 public initreward = 250000*1e18;
    uint256 public starttime = 1600272000; //utc+8 2020-09-17 00:00:00
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint public rewardTimes = 0;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event GovernTransfer(address indexed user, address indexed govern, uint256 reward);

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public updateReward(msg.sender) checkhalve checkStart{ 
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) checkStart{
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkhalve checkStart{
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            uint256 amount = reward.mul(95).div(100);
            uint256 fee = reward.sub(amount);
            kani.safeTransfer(msg.sender, amount);
            emit RewardPaid(msg.sender, amount);
            kani.approve(govern, fee);
            Govern g = Govern(govern);
            g.safeMakeProfit(fee);
            emit GovernTransfer(msg.sender, govern, fee);
        }
    }

    modifier checkhalve(){
        if (block.timestamp >= periodFinish && rewardTimes < 12) {
            if(rewardTimes < 11)    initreward = initreward.mul(50).div(100);
            kani.mint(address(this),initreward);
            rewardRate = initreward.div(DURATION);
            periodFinish = block.timestamp.add(DURATION);
            rewardTimes = rewardTimes.add(1);
            emit RewardAdded(initreward);
        }
        _;
    }

    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }
        kani.mint(address(this),reward);
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        rewardTimes = rewardTimes.add(1);
        emit RewardAdded(reward);
    }
}
