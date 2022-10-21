pragma solidity 0.8.2;

import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IAxon} from "./interfaces/IAxon.sol";

contract Gauge is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable NEURON;
    IAxon public immutable AXON;

    IERC20 public immutable TOKEN;
    address public immutable DISTRIBUTION;
    uint256 public constant DURATION = 7 days;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    modifier onlyDistribution() {
        require(
            msg.sender == DISTRIBUTION,
            "Caller is not RewardsDistribution contract"
        );
        _;
    }

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 public _totalSupply;
    uint256 public derivedSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public derivedBalances;
    mapping(address => uint256) private _base;

    constructor(
        address _token,
        address _neuron,
        address _axon
    ) {
        NEURON = IERC20(_neuron);
        AXON = IAxon(_axon);
        TOKEN = IERC20(_token);
        DISTRIBUTION = msg.sender;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(derivedSupply)
            );
    }

    function derivedBalance(address account) public view returns (uint256) {
        uint256 _balance = _balances[account];
        uint256 _derived = _balance.mul(40).div(100);
        uint256 axonMultiplier = 0;
        uint256 axonTotalSupply = AXON.totalSupply();
        if (axonTotalSupply != 0) {
            axonMultiplier = AXON.balanceOf(account).div(AXON.totalSupply());
        }
        uint256 _adjusted = (_totalSupply.mul(axonMultiplier)).mul(60).div(100);
        return Math.min(_derived.add(_adjusted), _balance);
    }

    function kick(address account) public {
        uint256 _derivedBalance = derivedBalances[account];
        derivedSupply = derivedSupply.sub(_derivedBalance);
        _derivedBalance = derivedBalance(account);
        derivedBalances[account] = _derivedBalance;
        derivedSupply = derivedSupply.add(_derivedBalance);
    }

    function earned(address account) public view returns (uint256) {
        return
            derivedBalances[account]
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(DURATION);
    }

    function depositAll() external {
        _deposit(TOKEN.balanceOf(msg.sender), msg.sender, msg.sender);
    }

    function deposit(uint256 amount) external {
        _deposit(amount, msg.sender, msg.sender);
    }

    function depositFor(uint256 amount, address account) external {
        _deposit(amount, account, account);
    }

    function depositFromSenderFor(uint256 amount, address account) external {
        _deposit(amount, msg.sender, account);
    }

    function depositStateUpdate(address holder, uint256 amount)
        internal
        updateReward(holder)
    {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[holder] = _balances[holder].add(amount);
        emit Staked(holder, amount);
    }

    function depositStateUpdateByPool(address holder, uint256 amount) external {
        require(
            msg.sender == address(TOKEN),
            "State update without transfer can only be called by pool"
        );
        depositStateUpdate(holder, amount);
    }

    function _deposit(
        uint256 amount,
        address spender,
        address recipient
    ) internal nonReentrant {
        depositStateUpdate(recipient, amount);
        TOKEN.safeTransferFrom(spender, address(this), amount);
    }

    function withdrawAll() external {
        _withdraw(_balances[msg.sender]);
    }

    function withdraw(uint256 amount) external {
        _withdraw(amount);
    }

    function _withdraw(uint256 amount)
        internal
        nonReentrant
    {
        withdrawStateUpdate(msg.sender, amount);
        TOKEN.safeTransfer(msg.sender, amount);
    }

    function withdrawStateUpdate(address holder, uint256 amount) internal updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[holder] = _balances[holder].sub(amount);
        emit Withdrawn(holder, amount);
    }

    // We use this function when withdraw right from pool. No transfer because after that we burn this amount from contract.
    function withdrawAllStateUpdateByPool(address holder)
        external
        nonReentrant
        returns (uint256)
    {
        require(
            msg.sender == address(TOKEN),
            "Only corresponding pool can withdraw tokens for someone"
        );
        uint256 amount = _balances[holder];
        withdrawStateUpdate(holder, amount);
        return amount;
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            NEURON.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        _withdraw(_balances[msg.sender]);
        getReward();
    }

    function notifyRewardAmount(uint256 reward)
        external
        onlyDistribution
        updateReward(address(0))
    {
        NEURON.safeTransferFrom(DISTRIBUTION, address(this), reward);
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(DURATION);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = NEURON.balanceOf(address(this));
        require(
            rewardRate <= balance.div(DURATION),
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
        if (account != address(0)) {
            kick(account);
        }
    }

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}

