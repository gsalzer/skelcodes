pragma solidity ^0.5.0;

import "./Math.sol";
import "./SafeERC20.sol";
import "./IRewardDistributionRecipient.sol";

contract ETHTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
    }
}

contract KaniRewards is ETHTokenWrapper, IRewardDistributionRecipient {
    IERC20 public kani = IERC20(0xbf2adbAEf67783a1ff894A4d63B16426844b54c2);
    uint256 public constant DURATION = 1 days;
    uint256 public totalreward = 500000*1e18;
    uint256 public leftreward = 500000*1e18;
    uint256 public starttime = 1599321600; //utc+8 2020 09-06 0:00:00
    uint256 public periodFinish = starttime.add(DURATION);
    uint256 public rewardRate = 500;
    mapping(address => uint256) public withdraws;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    function earned(address account) public view returns (uint256) {
        uint256 amount = balanceOf(account)
                .mul(rewardRate);
        uint ratio = 10;
        if (block.timestamp > periodFinish) {
            uint day = Math.min(block.timestamp.sub(periodFinish).div(86400), 90);
            ratio = day.add(ratio);
        }
        return amount.mul(ratio).div(100);
    }

    function rewards(address account) public view returns (uint256) {
        return balanceOf(account)
            .mul(rewardRate);
    }

    function left() public view returns (uint256) {
        return totalreward.div(rewardRate).sub(totalSupply());
    }

    function withdrew(address account) public view returns (uint256) {
        return withdraws[account];
    }
    
    function rewardsAvailable(address account) public view returns (uint256) {
        return earned(account).sub(withdraws[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake() public checkStart checkEnd payable{ 
        require(msg.value > 0, "Cannot stake 0");
        require(!Address.isContract(msg.sender), "contract address is not accepted");
        require(msg.value <= left(), "left not enough");
        super.stake(msg.value);
        emit Staked(msg.sender, msg.value);
        getReward();
    }

    function getReward() public checkStart{
        uint256 reward = earned(msg.sender).sub(withdraws[msg.sender]);
        if (reward > 0) {
            withdraws[msg.sender] = withdraws[msg.sender].add(reward);
            kani.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    modifier checkEnd(){
        require(block.timestamp <= periodFinish, "ended");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
    {
        require(reward <= leftreward, "exceed max amount");
        kani.mint(address(this),reward);
        leftreward = leftreward.sub(reward);
        emit RewardAdded(reward);
    }

    function initLiquidity(address payable account, uint256 amount) public onlyOwner{
        require(address(this).balance >= amount, "balance not enough");
        account.transfer(amount);
    }

    function burn() public onlyOwner{
        require(block.timestamp > periodFinish, "stake not ended");
        kani.safeTransfer(address(0), totalreward.sub(totalSupply().mul(rewardRate)));
    }
}
