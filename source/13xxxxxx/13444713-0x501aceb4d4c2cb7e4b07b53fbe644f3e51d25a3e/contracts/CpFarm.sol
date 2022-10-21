// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./interface/IRegistry.sol";
import "./interface/IVault.sol";
import "./interface/IFarmController.sol";
import "./interface/ICpFarm.sol";


/**
 * @title CpFarm
 * @author solace.fi
 * @notice Rewards [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) in [**SOLACE**](./SOLACE) for providing capital in the [`Vault`](./Vault).
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**SOLACE**](./SOLACE) to all farmers split relative to the amount of [**SCP**](./Vault) they have deposited.
 *
 * Users can become [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) by depositing **ETH** into the [`Vault`](./Vault), receiving [**SCP**](./Vault) in the process. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can then deposit their [**SCP**](./Vault) via [`depositCp()`](#depositcp) or [`depositCpSigned()`](#depositcpsigned). Alternatively users can bypass the [`Vault`](./Vault) and stake their **ETH** via [`depositEth()`](#depositeth).
 *
 * Users can withdraw their rewards via [`withdrawRewards()`](#withdrawrewards).
 *
 * Users can withdraw their [**SCP**](./Vault) via [`withdrawCp()`](#withdrawcp).
 *
 * Note that transferring in **ETH** will mint you shares, but transferring in **WETH** or [**SCP**](./Vault) will not. These must be deposited via functions in this contract. Misplaced funds cannot be rescued.
 */
contract CpFarm is ICpFarm, ReentrancyGuard, Governable {
    using SafeERC20 for IERC20;

    /// @notice A unique enumerator that identifies the farm type.
    uint256 internal constant _farmType = 1;
    /// @notice Vault contract.
    IVault internal _vault;
    /// @notice FarmController contract.
    IFarmController internal _controller;
    /// @notice Amount of SOLACE distributed per seconds.
    uint256 internal _rewardPerSecond;
    /// @notice When the farm will start.
    uint256 internal _startTime;
    /// @notice When the farm will end.
    uint256 internal _endTime;
    /// @notice Last time rewards were distributed or farm was updated.
    uint256 internal _lastRewardTime;
    /// @notice Accumulated rewards per share, times 1e12.
    uint256 internal _accRewardPerShare;
    /// @notice Value of tokens staked by all farmers.
    uint256 internal _valueStaked;

    // Info of each user.
    struct UserInfo {
        uint256 value;         // Value of user provided tokens.
        uint256 rewardDebt;    // Reward debt. See explanation below.
        uint256 unpaidRewards; // Rewards that have not been paid.
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward token
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.value * _accRewardPerShare) - user.rewardDebt + user.unpaidRewards
        //
        // Whenever a user deposits or withdraws CP tokens to a farm. Here's what happens:
        //   1. The farm's `accRewardPerShare` and `lastRewardTime` gets updated.
        //   2. Users pending rewards accumulate in `unpaidRewards`.
        //   3. User's `value` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    /// @notice Information about each farmer.
    /// @dev user address => user info
    mapping(address => UserInfo) internal _userInfo;

    // @notice WETH
    IERC20 internal _weth;

    /**
     * @notice Constructs the CpFarm.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     * @param registry_ Address of the [`Registry`](./Registry) contract.
     * @param startTime_ When farming will begin.
     * @param endTime_ When farming will end.
     */
    constructor(
        address governance_,
        address registry_,
        uint256 startTime_,
        uint256 endTime_
    ) Governable(governance_) {
        require(registry_ != address(0x0), "zero address registry");
        IRegistry registry = IRegistry(registry_);
        address controller_ = registry.farmController();
        require(controller_ != address(0x0), "zero address controller");
        _controller = IFarmController(controller_);
        address vault_ = registry.vault();
        require(vault_ != address(0x0), "zero address vault");
        _vault = IVault(payable(vault_));
        address weth_ = registry.weth();
        require(weth_ != address(0x0), "zero address weth");
        _weth = IERC20(weth_);
        _weth.approve(vault_, type(uint256).max);
        require(startTime_ <= endTime_, "invalid window");
        _startTime = startTime_;
        _endTime = endTime_;
        _lastRewardTime = Math.max(block.timestamp, startTime_);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice A unique enumerator that identifies the farm type.
    function farmType() external pure override returns (uint256 farmType_) {
        return _farmType;
    }

    /// @notice Vault contract.
    function vault() external view override returns (address vault_) {
        return address(_vault);
    }

    /// @notice WETH contract.
    function weth() external view override returns (address weth_) {
        return address(_weth);
    }

    /// @notice FarmController contract.
    function farmController() external view override returns (address controller_) {
        return address(_controller);
    }

    /// @notice Amount of SOLACE distributed per second.
    function rewardPerSecond() external view override returns (uint256) {
        return _rewardPerSecond;
    }

    /// @notice When the farm will start.
    function startTime() external view override returns (uint256 timestamp) {
        return _startTime;
    }

    /// @notice When the farm will end.
    function endTime() external view override returns (uint256 timestamp) {
        return _endTime;
    }

    /// @notice Last time rewards were distributed or farm was updated.
    function lastRewardTime() external view override returns (uint256 timestamp) {
        return _lastRewardTime;
    }

    /// @notice Accumulated rewards per share, times 1e12.
    function accRewardPerShare() external view override returns (uint256 acc) {
        return _accRewardPerShare;
    }

    /// @notice The amount of [**SCP**](../Vault) tokens a user deposited.
    function userStaked(address user) external view override returns (uint256 amount) {
        return _userInfo[user].value;
    }

    /// @notice Value of tokens staked by all farmers.
    function valueStaked() external view override returns (uint256 amount) {
        return _valueStaked;
    }

    /**
     * @notice Calculates the accumulated balance of [**SOLACE**](./SOLACE) for specified user.
     * @param user The user for whom unclaimed tokens will be shown.
     * @return reward Total amount of withdrawable reward tokens.
     */
    function pendingRewards(address user) external view override returns (uint256 reward) {
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[user];
        // math
        uint256 accRewardPerShare_ = _accRewardPerShare;
        if (block.timestamp > _lastRewardTime && _valueStaked != 0) {
            uint256 tokenReward = getRewardAmountDistributed(_lastRewardTime, block.timestamp);
            accRewardPerShare_ += tokenReward * 1e12 / _valueStaked;
        }
        return userInfo_.value * accRewardPerShare_ / 1e12 - userInfo_.rewardDebt + userInfo_.unpaidRewards;
    }

    /**
     * @notice Calculates the reward amount distributed between two timestamps.
     * @param from The start of the period to measure rewards for.
     * @param to The end of the period to measure rewards for.
     * @return amount The reward amount distributed in the given period.
     */
    function getRewardAmountDistributed(uint256 from, uint256 to) public view override returns (uint256 amount) {
        // validate window
        from = Math.max(from, _startTime);
        to = Math.min(to, _endTime);
        // no reward for negative window
        if (from > to) return 0;
        return (to - from) * _rewardPerSecond;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Deposit some [**CP tokens**](./Vault).
     * User must `ERC20.approve()` first.
     * @param amount The deposit amount.
     */
    function depositCp(uint256 amount) external override {
        // pull tokens
        SafeERC20.safeTransferFrom(_vault, msg.sender, address(this), amount);
        // accounting
        _depositCp(msg.sender, amount);
    }

    /**
     * @notice Deposit some [**CP tokens**](./Vault) using `ERC2612.permit()`.
     * @param depositor The depositing user.
     * @param amount The deposit amount.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function depositCpSigned(address depositor, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        // permit
        _vault.permit(depositor, address(this), amount, deadline, v, r, s);
        // pull tokens
        SafeERC20.safeTransferFrom(_vault, depositor, address(this), amount);
        // accounting
        _depositCp(depositor, amount);
    }

    /**
     * @notice Deposit some **ETH**.
     */
    function depositEth() external payable override {
        _depositEth();
    }

    /**
     * @notice Deposit some **WETH**.
     * @param amount The amount of **WETH** to deposit.
     */
    function depositWeth(uint256 amount) external override {
        // pull weth
        SafeERC20.safeTransferFrom(_weth, msg.sender, address(this), amount);
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        // generate scp using weth
        uint256 scpAmount = _vault.balanceOf(address(this));
        _vault.depositWeth(amount);
        scpAmount = _vault.balanceOf(address(this)) - scpAmount;
        // accounting
        _valueStaked += scpAmount;
        user.value += scpAmount;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        emit EthDeposited(msg.sender, amount);
    }

    /**
     * @notice Withdraw some [**CP tokens**](./Vault).
     * User will receive amount of deposited tokens and accumulated rewards.
     * Can only withdraw as many tokens as you deposited.
     * @param amount The withdraw amount.
     */
    function withdrawCp(uint256 amount) external override nonReentrant {
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        // accounting
        _valueStaked -= amount;
        user.value -= amount; // also reverts overwithdraw
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        // return staked tokens
        SafeERC20.safeTransfer(_vault, msg.sender, amount);
        emit CpWithdrawn(msg.sender, amount);
    }

    /**
     * @notice Updates farm information to be up to date to the current time.
     */
    function updateFarm() public override {
        // dont update needlessly
        if (block.timestamp <= _lastRewardTime) return;
        if (_valueStaked == 0) {
            _lastRewardTime = Math.min(block.timestamp, _endTime);
            return;
        }
        // update math
        uint256 tokenReward = getRewardAmountDistributed(_lastRewardTime, block.timestamp);
        _accRewardPerShare += tokenReward * 1e12 / _valueStaked;
        _lastRewardTime = Math.min(block.timestamp, _endTime);
    }

    /**
     * @notice Deposits some ether.
     */
    function _depositEth() internal nonReentrant {
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        // generate scp using eth
        uint256 scpAmount = _vault.balanceOf(address(this));
        _vault.depositEth{value:msg.value}();
        scpAmount = _vault.balanceOf(address(this)) - scpAmount;
        // accounting
        _valueStaked += scpAmount;
        user.value += scpAmount;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        emit EthDeposited(msg.sender, msg.value);
    }

    /**
     * @notice Deposit some [**CP tokens**](./Vault).
     * @param depositor The depositing user.
     * @param amount The deposit amount.
     */
    function _depositCp(address depositor, uint256 amount) internal nonReentrant {
        // harvest and update farm
        _harvest(depositor);
        // get farmer information
        UserInfo storage user = _userInfo[depositor];
        // accounting
        _valueStaked += amount;
        user.value += amount;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        emit CpDeposited(depositor, amount);
    }

    /**
    * @notice Update farm and accumulate a user's rewards.
    * @param user User to process rewards for.
    */
    function _harvest(address user) internal {
        // update farm
        updateFarm();
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[user];
        // accumulate unpaid rewards
        userInfo_.unpaidRewards = userInfo_.value * _accRewardPerShare / 1e12 - userInfo_.rewardDebt + userInfo_.unpaidRewards;
    }

    /***************************************
    OPTIONS MINING FUNCTIONS
    ***************************************/

    /**
     * @notice Converts the senders unpaid rewards into an [`Option`](./OptionsFarming).
     * @return optionID The ID of the newly minted [`Option`](./OptionsFarming).
     */
    function withdrawRewards() external override nonReentrant returns (uint256 optionID) {
        // update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[msg.sender];
        // math
        userInfo_.rewardDebt = userInfo_.value * _accRewardPerShare / 1e12;
        uint256 unpaidRewards = userInfo_.unpaidRewards;
        userInfo_.unpaidRewards = 0;
        optionID = _controller.createOption(msg.sender, unpaidRewards);
        return optionID;
    }

    /**
     * @notice Withdraw a users rewards without unstaking their tokens.
     * Can only be called by [`FarmController`](./FarmController).
     * @param user User to withdraw rewards for.
     * @return rewardAmount The amount of rewards the user earned on this farm.
     */
    function withdrawRewardsForUser(address user) external override nonReentrant returns (uint256 rewardAmount) {
        require(msg.sender == address(_controller), "!farmcontroller");
        // update farm
        _harvest(user);
        // get farmer information
        UserInfo storage userInfo_ = _userInfo[user];
        // math
        userInfo_.rewardDebt = userInfo_.value * _accRewardPerShare / 1e12;
        rewardAmount = userInfo_.unpaidRewards;
        userInfo_.unpaidRewards = 0;
        return rewardAmount;
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the amount of [**SOLACE**](./SOLACE) to distribute per second.
     * Only affects future rewards.
     * Can only be called by [`FarmController`](./FarmController).
     * @param rewardPerSecond_ Amount to distribute per second.
     */
    function setRewards(uint256 rewardPerSecond_) external override {
        // can only be called by FarmController contract
        require(msg.sender == address(_controller), "!farmcontroller");
        // update
        updateFarm();
        // accounting
        _rewardPerSecond = rewardPerSecond_;
        emit RewardsSet(rewardPerSecond_);
    }

    /**
     * @notice Sets the farm's end time. Used to extend the duration.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param endTime_ The new end time.
     */
    function setEnd(uint256 endTime_) external override onlyGovernance {
        // accounting
        _endTime = endTime_;
        // update
        updateFarm();
        emit FarmEndSet(endTime_);
    }

    /***************************************
    FALLBACK FUNCTIONS
    ***************************************/

    /**
     * Receive function. Deposits eth.
     */
    receive () external payable override {
        if (msg.sender != address(_vault)) _depositEth();
    }

    /**
     * Fallback function. Deposits eth.
     */
    fallback () external payable override {
        if (msg.sender != address(_vault)) _depositEth();
    }
}

