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

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _tokenBalances;
    mapping(string => address) private _tokens;

    constructor() internal {
        _tokens["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        _tokens["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function balanceOf(string memory token, address account) public view returns (uint256) {
        return _tokenBalances[account][_tokens[token]];
    }

    function stake(string memory token, uint256 amount) public {
        require(_tokens[token] != address(0), "not supported");
        _totalSupply = _totalSupply.add(amount);
        _tokenBalances[msg.sender][_tokens[token]] = _tokenBalances[msg.sender][_tokens[token]].add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        IERC20 y = IERC20(_tokens[token]);
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(string memory token, uint256 amount) public {
        require(_tokens[token] != address(0), "not supported");
        if (amount <= 0) return;
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        _tokenBalances[msg.sender][_tokens[token]] = _tokenBalances[msg.sender][_tokens[token]].sub(amount);
        IERC20 y = IERC20(_tokens[token]);
        y.safeTransfer(msg.sender, amount);
    }
}

contract KaniRewards is LPTokenWrapper, IRewardDistributionRecipient {
    using SafeGovern for Govern;

    IERC20 public kani = IERC20(0x790aCe920bAF3af2b773D4556A69490e077F6B4A);
    uint256 public constant DURATION = 100 days;

    uint256 public totalReward = 500000*1e18;
    uint256 public rewardRate = 0;
    uint256 public starttime = 1600142400; //utc+8 2020 09-15 12:00:00
    uint256 public periodFinish = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    address govern = 0x3a8Ff8b9DE3429EA84DFC8e8f13072C6838d51aF; // Governance address

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, string token, uint256 amount);
    event Withdrawn(address indexed user, string token, uint256 amount);
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
    function stake(string memory token, uint256 amount) public updateReward(msg.sender) checkStart{
        require(amount > 0, "Cannot stake 0");
        super.stake(token, amount);
        emit Staked(msg.sender, token, amount);
    }

    function withdraw(string memory token, uint256 amount) public updateReward(msg.sender) checkStart{
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(token, amount);
        emit Withdrawn(msg.sender, token, amount);
    }

    function withdraw() public updateReward(msg.sender) checkStart {
        string memory token = "USDT";
        uint256 amount = balanceOf(token, msg.sender);
        if (amount > 0) {
            super.withdraw(token, amount);
            emit Withdrawn(msg.sender, token, amount);
        }
        token = "DAI";
        amount = balanceOf(token, msg.sender);
        if (amount > 0) {
            super.withdraw(token, amount);
            emit Withdrawn(msg.sender, token, amount);
        }
    }

    function exit() external {
        withdraw();
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkStart{
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

    modifier checkStart(){
        require(block.timestamp > starttime,"not start");
        _;
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        require(reward == totalReward, "inited");
        kani.mint(address(this),totalReward);
        lastUpdateTime = block.timestamp;
        rewardRate = reward.div(DURATION);
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(totalReward);
    }
}
