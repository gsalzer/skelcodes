// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Governable.sol";
import "./interface/IRegistry.sol";
import "./interface/IPolicyManager.sol";
import "./interface/ISptFarm.sol";


/**
 * @title ISptFarm
 * @author solace.fi
 * @notice Rewards [**Policyholders**](/docs/protocol/policy-holder) in [**Options**](../OptionFarming) for staking their [**Policies**](./PolicyManager).
 *
 * Over the course of `startTime` to `endTime`, the farm distributes `rewardPerSecond` [**Options**](../OptionFarming) to all farmers split relative to the amount of [**SCP**](../Vault) they have deposited.
 *
 * Users can become [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) by depositing **ETH** into the [`Vault`](../Vault), receiving [**SCP**](../Vault) in the process. [**Capital Providers**](/docs/user-guides/capital-provider/cp-role-guide) can then deposit their [**SCP**](../Vault) via [`depositCp()`](#depositcp) or [`depositCpSigned()`](#depositcpsigned). Alternatively users can bypass the [`Vault`](../Vault) and stake their **ETH** via [`depositEth()`](#depositeth).
 *
 * Users can withdraw their rewards via [`withdrawRewards()`](#withdrawrewards).
 *
 * Users can withdraw their [**SCP**](../Vault) via [`withdrawCp()`](#withdrawcp).
 *
 * Note that transferring in **ETH** will mint you shares, but transferring in **WETH** or [**SCP**](../Vault) will not. These must be deposited via functions in this contract. Misplaced funds cannot be rescued.
 */
contract SptFarm is ISptFarm, ReentrancyGuard, Governable {
    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice A unique enumerator that identifies the farm type.
    uint256 internal constant _farmType = 3;
    /// @notice PolicyManager contract.
    IPolicyManager internal _policyManager;
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
    /// @notice Value of policys staked by all farmers.
    uint256 internal _valueStaked;

    // Info of each user.
    struct UserInfo {
        uint256 value;         // Value of user provided policys.
        uint256 rewardDebt;    // Reward debt. See explanation below.
        uint256 unpaidRewards; // Rewards that have not been paid.
        //
        // We do some fancy math here. Basically, any point in time, the amount of reward token
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.value * _accRewardPerShare) - user.rewardDebt + user.unpaidRewards
        //
        // Whenever a user deposits or withdraws policies to a farm. Here's what happens:
        //   1. The farm's `accRewardPerShare` and `lastRewardTime` gets updated.
        //   2. Users pending rewards accumulate in `unpaidRewards`.
        //   3. User's `value` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    /// @notice Information about each farmer.
    /// @dev user address => user info
    mapping(address => UserInfo) internal _userInfo;

    // list of tokens deposited by user
    mapping(address => EnumerableSet.UintSet) internal _userDeposited;

    struct PolicyInfo {
        address depositor;
        uint256 value;
    }

    // policy id => policy info
    mapping(uint256 => PolicyInfo) internal _policyInfo;

    /**
     * @notice Constructs the SptFarm.
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
        address policyManager_ = registry.policyManager();
        require(policyManager_ != address(0x0), "zero address policymanager");
        _policyManager = IPolicyManager(policyManager_);
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

    /// @notice [`PolicyManager`](./PolicyManager) contract.
    function policyManager() external view override returns (address policyManager_) {
        return address(_policyManager);
    }

    /**
     * @notice Returns the count of [**policies**](./PolicyManager) that a user has deposited onto the farm.
     * @param user The user to check count for.
     * @return count The count of deposited [**policies**](./PolicyManager).
     */
    function countDeposited(address user) external view override returns (uint256 count) {
        return _userDeposited[user].length();
    }

    /**
     * @notice Returns the list of [**policies**](./PolicyManager) that a user has deposited onto the farm and their values.
     * @param user The user to list deposited policies.
     * @return policyIDs The list of deposited policies.
     * @return policyValues The values of the policies.
     */
    function listDeposited(address user) external view override returns (uint256[] memory policyIDs, uint256[] memory policyValues) {
        uint256 length = _userDeposited[user].length();
        policyIDs = new uint256[](length);
        policyValues = new uint256[](length);
        for(uint256 i = 0; i < length; ++i) {
            uint256 policyID = _userDeposited[user].at(i);
            policyIDs[i] = policyID;
            policyValues[i] = _policyInfo[policyID].value;
        }
        return (policyIDs, policyValues);
    }

    /**
     * @notice Returns the ID of a [**Policies**](./PolicyManager) that a user has deposited onto a farm and its value.
     * @param user The user to get policyID for.
     * @param index The farm-based index of the policy.
     * @return policyID The ID of the deposited [**policy**](./PolicyManager).
     * @return policyValue The value of the [**policy**](./PolicyManager).
     */
    function getDeposited(address user, uint256 index) external view override returns (uint256 policyID, uint256 policyValue) {
        policyID = _userDeposited[user].at(index);
        policyValue = _policyInfo[policyID].value;
        return (policyID, policyValue);
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

    /// @notice The value of [**policies**](./PolicyManager) a user deposited.
    function userStaked(address user) external view override returns (uint256 amount) {
        return _userInfo[user].value;
    }

    /// @notice Value of [**policies**](./PolicyManager) staked by all farmers.
    function valueStaked() external view override returns (uint256 amount) {
        return _valueStaked;
    }

    /// @notice Information about a deposited policy.
    function policyInfo(uint256 policyID) external view override returns (address depositor, uint256 value) {
        PolicyInfo storage policyInfo_ = _policyInfo[policyID];
        return (policyInfo_.depositor, policyInfo_.value);
    }

    /**
     * @notice Calculates the accumulated balance of [**SOLACE**](./SOLACE) for specified user.
     * @param user The user for whom unclaimed rewards will be shown.
     * @return reward Total amount of withdrawable rewards.
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
     * @notice Deposit a [**policy**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyID The ID of the policy to deposit.
     */
    function depositPolicy(uint256 policyID) external override {
        // pull policy
        _policyManager.transferFrom(msg.sender, address(this), policyID);
        // accounting
        _deposit(msg.sender, policyID);
    }

    /**
     * @notice Deposit a [**policy**](./PolicyManager) using permit.
     * @param depositor The depositing user.
     * @param policyID The ID of the policy to deposit.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
     */
    function depositPolicySigned(address depositor, uint256 policyID, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external override {
        // permit
        _policyManager.permit(address(this), policyID, deadline, v, r, s);
        // pull policy
        _policyManager.transferFrom(depositor, address(this), policyID);
        // accounting
        _deposit(depositor, policyID);
    }

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager).
     * User must `ERC721.approve()` or `ERC721.setApprovalForAll()` first.
     * @param policyIDs The IDs of the policies to deposit.
     */
    function depositPolicyMulti(uint256[] memory policyIDs) external override {
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // pull policy
            _policyManager.transferFrom(msg.sender, address(this), policyID);
            // accounting
            _deposit(msg.sender, policyID);
        }
    }

    /**
     * @notice Deposit multiple [**policies**](./PolicyManager) using permit.
     * @param depositors The depositing users.
     * @param policyIDs The IDs of the policies to deposit.
     * @param deadlines Times the transactions must go through before.
     * @param vs secp256k1 signatures
     * @param rs secp256k1 signatures
     * @param ss secp256k1 signatures
     */
    function depositPolicySignedMulti(address[] memory depositors, uint256[] memory policyIDs, uint256[] memory deadlines, uint8[] memory vs, bytes32[] memory rs, bytes32[] memory ss) external override {
        require(depositors.length == policyIDs.length && depositors.length == deadlines.length && depositors.length == vs.length && depositors.length == rs.length && depositors.length == ss.length, "length mismatch");
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // permit
            _policyManager.permit(address(this), policyID, deadlines[i], vs[i], rs[i], ss[i]);
            // pull policy
            _policyManager.transferFrom(depositors[i], address(this), policyID);
            // accounting
            _deposit(depositors[i], policyID);
        }
    }

    /**
     * @notice Performs the internal accounting for a deposit.
     * @param depositor The depositing user.
     * @param policyID The ID of the policy to deposit.
     */
    function _deposit(address depositor, uint256 policyID) internal {
        // get policy
        (/* address policyholder */, /* address product */, uint256 coverAmount, uint40 expirationBlock, uint24 price, /* bytes calldata positionDescription */) = _policyManager.getPolicyInfo(policyID);
        require(expirationBlock > block.number, "policy is expired");
        // harvest and update farm
        _harvest(depositor);
        // get farmer information
        UserInfo storage user = _userInfo[depositor];
        // record position
        uint256 policyValue = coverAmount * uint256(price); // a multiple of premium per block
        PolicyInfo memory policyInfo_ = PolicyInfo({
            depositor: depositor,
            value: policyValue
        });
        _policyInfo[policyID] = policyInfo_;
        // accounting
        user.value += policyValue;
        _valueStaked += policyValue;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        _userDeposited[depositor].add(policyID);
        // emit event
        emit PolicyDeposited(depositor, policyID);
    }

    /**
     * @notice Withdraw a [**policy**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyID The ID of the policy to withdraw.
     */
    function withdrawPolicy(uint256 policyID) external override {
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        // get policy info
        PolicyInfo memory policyInfo_ = _policyInfo[policyID];
        // cannot withdraw a policy you didnt deposit
        require(policyInfo_.depositor == msg.sender, "not your policy");
        // accounting
        user.value -= policyInfo_.value;
        _valueStaked -= policyInfo_.value;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
        // delete policy info
        delete _policyInfo[policyID];
        // return staked policy
        _userDeposited[msg.sender].remove(policyID);
        _policyManager.safeTransferFrom(address(this), msg.sender, policyID);
        // emit event
        emit PolicyWithdrawn(msg.sender, policyID);
    }

    /**
     * @notice Withdraw multiple [**policies**](./PolicyManager).
     * Can only withdraw policies you deposited.
     * @param policyIDs The IDs of the policies to withdraw.
     */
    function withdrawPolicyMulti(uint256[] memory policyIDs) external override {
        // harvest and update farm
        _harvest(msg.sender);
        // get farmer information
        UserInfo storage user = _userInfo[msg.sender];
        uint256 userValue_ = user.value;
        uint256 valueStaked_ = _valueStaked;
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // get policy info
            PolicyInfo memory policyInfo_ = _policyInfo[policyID];
            // cannot withdraw a policy you didnt deposit
            require(policyInfo_.depositor == msg.sender, "not your policy");
            // accounting
            userValue_ -= policyInfo_.value;
            valueStaked_ -= policyInfo_.value;
            // delete policy info
            delete _policyInfo[policyID];
            // return staked policy
            _userDeposited[msg.sender].remove(policyID);
            _policyManager.safeTransferFrom(address(this), msg.sender, policyID);
            // emit event
            emit PolicyWithdrawn(msg.sender, policyID);
        }
        // accounting
        user.value = userValue_;
        _valueStaked = valueStaked_;
        user.rewardDebt = user.value * _accRewardPerShare / 1e12;
    }

    /**
     * @notice Burns expired policies.
     * @param policyIDs The list of expired policies.
     */
    function updateActivePolicies(uint256[] calldata policyIDs) external override {
        // update farm
        updateFarm();
        // for each policy to burn
        for(uint256 i = 0; i < policyIDs.length; i++) {
            uint256 policyID = policyIDs[i];
            // get policy info
            PolicyInfo memory policyInfo_ = _policyInfo[policyID];
            // if policy is on the farm and policy is expired or burnt
            if(policyInfo_.depositor != address(0x0) && !_policyManager.policyIsActive(policyID)) {
                // get farmer information
                UserInfo storage user = _userInfo[policyInfo_.depositor];
                // accounting
                user.value -= policyInfo_.value;
                _valueStaked -= policyInfo_.value;
                user.rewardDebt = user.value * _accRewardPerShare / 1e12;
                // delete policy info
                delete _policyInfo[policyID];
                // remove staked policy
                _userDeposited[policyInfo_.depositor].remove(policyID);
                // emit event
                emit PolicyWithdrawn(address(0x0), policyID);
            }
        }
        // policymanager needs to do its own accounting
        _policyManager.updateActivePolicies(policyIDs);
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
     * @notice Withdraw a users rewards without unstaking their policys.
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
}

