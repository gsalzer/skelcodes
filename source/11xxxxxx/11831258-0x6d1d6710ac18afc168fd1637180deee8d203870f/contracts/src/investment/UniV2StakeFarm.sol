/*
 * Copyright (C) 2020-2021 The Wolfpack
 * This file is part of wolves.finance - https://github.com/wolvesofwallstreet/wolves.finance
 *
 * SPDX-License-Identifier: Apache-2.0
 * See the file LICENSES/README.md for more information.
 */

pragma solidity >=0.6.0 <0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import './interfaces/IController.sol';
import './interfaces/IFarm.sol';
import './interfaces/IStakeFarm.sol';
import '../../interfaces/uniswap/IUniswapV2Pair.sol';

contract UniV2StakeFarm is IFarm, IStakeFarm, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  IUniswapV2Pair public stakingToken;
  uint256 public override periodFinish = 0;
  uint256 public rewardRate = 0;
  uint256 public rewardsDuration = 7 days;
  uint256 public lastUpdateTime;
  uint256 public rewardPerTokenStored;
  uint256 private availableRewards;

  mapping(address => uint256) public userRewardPerTokenPaid;
  mapping(address => uint256) public rewards;
  // TODO: Remove next 2 lines after dapp launch (special reward condition)
  mapping(address => uint256) private firstStakeTime;
  uint256 private constant ETH_LIMIT = 2e17;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  // Unique name of this farm instance, used in controller
  string private _farmName;
  // Uniswap route to get price for token 0 in pair
  IUniswapV2Pair public immutable route;
  // The address of the controller
  IController public controller;
  // The direction of the uniswap pairs
  uint8 public pairDirection;

  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _owner,
    string memory _name,
    address _stakingToken,
    address _rewardToken,
    address _controller,
    address _route
  ) {
    _farmName = _name;
    stakingToken = IUniswapV2Pair(_stakingToken);
    controller = IController(_controller);
    route = IUniswapV2Pair(_route);

    address routeLink;

    /**
     * @dev Calculate the sort order of the keys once to save gas in further steps
     *
     * Our token sort order is:
     * - stakeToken: token0[routeLink], token1[rewardToken]
     * - route:      token0[routeLink], token1[stableCoin]
     *
     * If the sort order differs, we set one bit for each of both
     */
    if (stakingToken.token0() == _rewardToken) {
      pairDirection = 1;
      routeLink = stakingToken.token1();
    } else routeLink = stakingToken.token0();

    if (
      address(_route) != address(0) &&
      IUniswapV2Pair(_route).token1() == routeLink
    ) pairDirection |= 2;
    transferOwnership(_owner);
  }

  /* ========== VIEWS ========== */

  function farmName() external view override returns (string memory) {
    return _farmName;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return _balances[account];
  }

  function lastTimeRewardApplicable() public view returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
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
          .div(_totalSupply)
      );
  }

  function earned(address account) public view returns (uint256) {
    return
      _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
  }

  function getRewardForDuration() external view returns (uint256) {
    return rewardRate.mul(rewardsDuration);
  }

  function getUIData(address _user) external view returns (uint256[9] memory) {
    (uint112 reserve0, uint112 reserve1, uint256 price) = _getTokenUiData();
    uint256[9] memory result =
      [
        // Pool
        stakingToken.totalSupply(),
        (uint256(reserve0)),
        (uint256(reserve1)),
        price,
        // Stake
        _totalSupply,
        _balances[_user],
        rewardsDuration,
        rewardRate.mul(rewardsDuration),
        earned(_user)
      ];
    return result;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount)
    external
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, 'Cannot stake 0');

    /*(uint256 fee) = */
    controller.onDeposit(amount);

    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    IERC20(address(stakingToken)).safeTransferFrom(
      msg.sender,
      address(this),
      amount
    );

    // TODO: Remove after launch
    if (
      firstStakeTime[msg.sender] == 0 &&
      _ethAmount(_balances[msg.sender]) >= ETH_LIMIT
      // solhint-disable-next-line not-rely-on-time
    ) firstStakeTime[msg.sender] = block.timestamp;

    emit Staked(msg.sender, amount);
  }

  function unstake(uint256 amount)
    public
    override
    nonReentrant
    updateReward(msg.sender)
  {
    require(amount > 0, 'Cannot withdraw 0');

    /*(uint256 fee) = */
    controller.onWithdraw(amount);

    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    IERC20(address(stakingToken)).safeTransfer(msg.sender, amount);

    // TODO: Remove after launch
    if (
      firstStakeTime[msg.sender] > 0 &&
      (_balances[msg.sender] == 0 ||
        _ethAmount(_balances[msg.sender]) < ETH_LIMIT)
    ) firstStakeTime[msg.sender] = 0;

    emit Unstaked(msg.sender, amount);
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    updateReward(msg.sender)
    updateReward(recipient)
  {
    require(recipient != address(0), 'invalid address');
    require(amount > 0, 'zero amount');

    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfered(msg.sender, recipient, amount);
  }

  function getReward() public override nonReentrant updateReward(msg.sender) {
    uint256 reward = rewards[msg.sender];
    if (reward > 0) {
      rewards[msg.sender] = 0;
      availableRewards = availableRewards.sub(reward);
      controller.payOutRewards(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function exit() external override {
    unstake(_balances[msg.sender]);
    getReward();
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function setController(address newController)
    external
    override
    onlyController
  {
    controller = IController(newController);
    emit ControllerChanged(newController);
  }

  function notifyRewardAmount(uint256 reward)
    external
    override
    onlyController
    updateReward(address(0))
  {
    // solhint-disable-next-line not-rely-on-time
    if (block.timestamp >= periodFinish) {
      rewardRate = reward.div(rewardsDuration);
    } else {
      // solhint-disable-next-line not-rely-on-time
      uint256 remaining = periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(rewardRate);
      rewardRate = reward.add(leftover).div(rewardsDuration);
    }
    availableRewards = availableRewards.add(reward);

    // Ensure the provided reward amount is not more than the balance in the
    // contract.
    //
    // This keeps the reward rate in the right range, preventing overflows due
    // to very high values of rewardRate in the earned and rewardsPerToken
    // functions.
    //
    // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
    //
    require(
      rewardRate <= availableRewards.div(rewardsDuration),
      'Provided reward too high'
    );

    // solhint-disable-next-line not-rely-on-time
    lastUpdateTime = block.timestamp;
    // solhint-disable-next-line not-rely-on-time
    periodFinish = block.timestamp.add(rewardsDuration);

    emit RewardAdded(reward);
  }

  // We don't have any rebalancing here
  // solhint-disable-next-line no-empty-blocks
  function rebalance() external override onlyController {}

  // Added to support recovering LP Rewards from other systems to be distributed to holders
  function recoverERC20(address tokenAddress, uint256 tokenAmount)
    external
    onlyOwner
  {
    // Cannot recover the staking token or the rewards token
    require(
      tokenAddress != address(stakingToken),
      'pool tokens not recoverable'
    );
    IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
    emit Recovered(tokenAddress, tokenAmount);
  }

  function setRewardsDuration(uint256 _rewardsDuration)
    external
    override
    onlyOwner
  {
    require(
      // solhint-disable-next-line not-rely-on-time
      periodFinish == 0 || block.timestamp > periodFinish,
      'reward period not finished'
    );
    rewardsDuration = _rewardsDuration;
    emit RewardsDurationUpdated(rewardsDuration);
  }

  /* ========== PRIVATE ========== */

  function _ethAmount(uint256 amountToken) private view returns (uint256) {
    (uint112 reserve0, uint112 reserve1, ) = stakingToken.getReserves();

    // RouteLink is token1, swap
    if ((pairDirection & 1) != 0) reserve0 = reserve1;

    return (uint256(reserve0).mul(amountToken)).div(stakingToken.totalSupply());
  }

  /**
   * @dev Returns the reserves in order: ETH -> Token, ETH/stable
   */
  function _getTokenUiData()
    internal
    view
    returns (
      uint112,
      uint112,
      uint256
    )
  {
    (uint112 reserve0, uint112 reserve1, ) = stakingToken.getReserves();
    (uint112 reserve0R, uint112 reserve1R, ) =
      address(route) != address(0) ? route.getReserves() : (1, 1, 0);

    uint112 swap;

    // RouteLink is token1, swap
    if ((pairDirection & 1) != 0) {
      swap = reserve0;
      reserve0 = reserve1;
      reserve1 = swap;
    }

    // RouteLink is token1, swap
    if ((pairDirection & 2) != 0) {
      swap = reserve0R;
      reserve0R = reserve1R;
      reserve1R = swap;
    }

    return (reserve0, reserve1, uint256(reserve0R).mul(1e18).div(reserve1R));
  }

  /* ========== MODIFIERS ========== */

  modifier onlyController {
    require(_msgSender() == address(controller), 'not controller');
    _;
  }

  modifier updateReward(address account) {
    rewardPerTokenStored = rewardPerToken();
    lastUpdateTime = lastTimeRewardApplicable();
    if (account != address(0)) {
      rewards[account] = earned(account);
      userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
    _;
  }

  /* ========== EVENTS ========== */

  event RewardAdded(uint256 reward);
  event Staked(address indexed user, uint256 amount);
  event Unstaked(address indexed user, uint256 amount);
  event Transfered(address indexed from, address indexed to, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardsDurationUpdated(uint256 newDuration);
  event Recovered(address token, uint256 amount);
  event ControllerChanged(address newController);
}

