// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/Math.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "../lib/interfaces/IDepositContract.sol";
import "../SystemParameters.sol";
import "../lib/Lockable.sol";
import "../lib/interfaces/IAETH.sol";
import "../lib/interfaces/IFETH.sol";
import "../lib/interfaces/IConfig.sol";
import "../lib/interfaces/IStaking.sol";
import "../lib/interfaces/IDepositContract.sol";
import "../lib/Pausable.sol";

contract GlobalPool_R30 is Lockable, Pausable {

    using SafeMath for uint256;
    using Math for uint256;

    /* staker events */
    event StakePending(address indexed staker, uint256 amount);
    event StakeConfirmed(address indexed staker, uint256 amount);
    event StakeRemoved(address indexed staker, uint256 amount);

    /* pool events */
    event PoolOnGoing(bytes pool);
    event PoolCompleted(bytes pool);

    /* provider events */
    event ProviderSlashedAnkr(address indexed provider, uint256 ankrAmount, uint256 etherEquivalence);
    event ProviderSlashedEth(address indexed provider, uint256 amount);
    event ProviderToppedUpEth(address indexed provider, uint256 amount);
    event ProviderToppedUpAnkr(address indexed provider, uint256 amount);
    event ProviderExited(address indexed provider);

    /* rewards (AETH) */
    event RewardClaimed(address indexed staker, uint256 amount, bool isAETH);

    mapping(address => uint256) private _pendingUserStakes;
    mapping(address => uint256) private _userStakes;

    mapping(address => uint256) private _rewards;
    mapping(address => uint256) private _claims;

    mapping(address => uint256) private _etherBalances;
    mapping(address => uint256) private _slashings;

    mapping(address => uint256) private _exits;

    // Pending staker list
    address[] private _pendingStakers;
    // total pending amount
    uint256 private _pendingAmount;
    // total stakes of all users
    uint256 private _totalStakes;
    // total rewards for all stakers
    uint256 private _totalRewards;

    IAETH private _aethContract;

    IStaking private _stakingContract;

    SystemParameters private _systemParameters;

    address _depositContract;

    address[] private _pendingTemp;

    modifier notExitRecently(address provider) {
        require(block.number > _exits[provider].add(_configContract.getConfig("EXIT_BLOCKS")), "Recently exited");
        delete _exits[msg.sender];
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == owner() || msg.sender == _operator, "Operator: not allowed");
        _;
    }

    function initialize(IAETH aethContract, SystemParameters parameters, address depositContract) public initializer {
        __Ownable_init();

        _depositContract = depositContract;
        _aethContract = aethContract;
        _systemParameters = parameters;
        _paused["topUpETH"] = true;
        _paused["topUpANKR"] = true;
    }

    function multipleDeposit(bytes[] calldata pubkey,
        bytes[] calldata withdrawal_credentials,
        bytes[] calldata signature,
        bytes32[] calldata deposit_data_root) public onlyOperator {
        uint256 pubkeyLength = pubkey.length;
        require(
            pubkeyLength == withdrawal_credentials.length &&
            pubkeyLength == signature.length &&
            pubkeyLength == deposit_data_root.length, "Multiple Deposit: Array lengths must be equal");

        for(uint32 i = 0; i < pubkeyLength; i++) {
            _deposit(pubkey[i], withdrawal_credentials[i], signature[i], deposit_data_root[i]);
        }
    }

    function pushToBeacon(bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root) public onlyOperator {
        _deposit(pubkey, withdrawal_credentials, signature, deposit_data_root);
    }

    function _deposit(bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root) private {

        require(address(this).balance >= 32 ether, "pending ethers not enough");

        IDepositContract(_depositContract).deposit{value : 32 ether}(pubkey, withdrawal_credentials, signature, deposit_data_root);

        emit PoolOnGoing(pubkey);
    }

    function stake() public whenNotPaused("stake") notExitRecently(msg.sender) unlocked(msg.sender) payable {
        _stake(msg.sender, msg.value, true);
    }

    function customStake(address[] memory addresses, uint256[] memory amounts) public payable onlyOperator {
        require(addresses.length == amounts.length, "Addresses and amounts length must be equal");
        uint256 totalSent = 0;

        for(uint256 i = 0; i < amounts.length; i++) {
            totalSent += amounts[i];
            _stake(addresses[i], amounts[i], false);
        }

        require(msg.value == totalSent, "Total value must be same with sent");
    }

    function _stake(address staker, uint256 value, bool payRewards) private {
        uint256 minimumStaking = _configContract.getConfig("REQUESTER_MINIMUM_POOL_STAKING");

        require(value >= minimumStaking, "Value must be greater than zero");
        require(value % minimumStaking == 0, "Value must be multiple of minimum staking amount");

        _userStakes[staker] = _userStakes[staker].add(value);
        _totalStakes = _totalStakes.add(msg.value);

        uint256 _ratio = _aethContract.ratio();
        if (payRewards) {
            _aETHRewards[staker] = _aETHRewards[staker].add(value.mul(_ratio).div(1e18));
            _fETHRewards[staker][0] = _fETHRewards[staker][0].add(value);
            _fETHRewards[staker][1] = _fETHRewards[staker][1].add(value.mul(_fethMintBase).div(1 ether));
        }
        emit StakePending(staker, value);
        emit StakeConfirmed(staker, value);
    }

    function topUpETH() public whenNotPaused("topUpETH") notExitRecently(msg.sender) payable {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ETH_STAKING") <= msg.value, "Value must be greater than minimum amount");
        _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);
        //           _etherBalances[msg.sender] = _etherBalances[msg.sender].add(msg.value);

        _stake(msg.sender, msg.value, false);

        emit ProviderToppedUpEth(msg.sender, msg.value);
    }

    function topUpANKR(uint256 amount) public whenNotPaused("topUpANKR") notExitRecently(msg.sender) {
        require(_configContract.getConfig("PROVIDER_MINIMUM_ANKR_STAKING") <= amount, "Value must be greater than minimum amount");
        require(_stakingContract.freeze(msg.sender, amount), "Not enough allowance or balance");

        emit ProviderToppedUpAnkr(msg.sender, amount);
    }

    // slash provider with ethereum balance
    function slash(address provider, uint256 amount) public unlocked(provider) onlyOwner {
        require(amount > 0, "Amount should be greater than zero");
        _slashETH(provider, amount);
    }

    function providerExit() public {
        int256 available = availableEtherBalanceOf(msg.sender);
        address staker = msg.sender;
        require(available > 0, "Provider balance should be positive for exit");
        _exits[staker] = block.number;

        _etherBalances[staker] = 0;
        _slashings[staker] = 0;

        uint256 value = uint256(available);
        uint256 _ratio = _aethContract.ratio();

        _aETHRewards[staker] = _aETHRewards[staker].add(value.mul(_ratio).div(1e18));
        _fETHRewards[staker][0] = _fETHRewards[staker][0].add(value);
        _fETHRewards[staker][1] = _fETHRewards[staker][1].add(value.mul(_fethMintBase).div(1 ether));

        emit ProviderExited(msg.sender);
    }

    function claim() public whenNotPaused("claim") notExitRecently(msg.sender) {
        claimAETH();
    }

    function claimableRewardOf(address staker) public view returns (uint256) {
        // for backwards compatibility
        return claimableAETHRewardOf(staker);
    }

    function claimableAETHRewardOf(address staker) public view returns (uint256) {
        uint256 blocked = _etherBalances[staker];
        uint256 reward = _rewards[staker].sub(_claims[staker]);
        reward = blocked >= reward ? 0 : reward.sub(blocked);
        reward = _aETHRewards[staker].add(reward);

        return reward;
    }

    function claimableAETHFRewardOf(address staker) public view returns (uint256) {
        return _fETHRewards[staker][0];
    }

    function claimAETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimable = claimableAETHRewardOf(staker);
        require(claimable > 0, "claimable reward zero");

        _fETHRewards[staker][0] = 0;
        _fETHRewards[staker][1] = 0;
        _aETHRewards[staker] = 0;
        uint256 oldReward = _rewards[staker].sub(_claims[staker]);
        if (oldReward > 0) {
            _claims[staker] = _claims[staker].add(oldReward);
        }

        _aethContract.mint(staker, claimable);
        emit RewardClaimed(staker, claimable, true);
    }

    function claimFETH() whenNotPaused("claim") public {
        address staker = msg.sender;
        uint256 claimable = claimableAETHFRewardOf(staker);
        uint256 shares = _fETHRewards[staker][1];
        require(claimable > 0, "claimable reward zero");

        _fETHRewards[staker][0] = 0;
        _fETHRewards[staker][1] = 0;
        _aETHRewards[staker] = 0;

        _fethContract.mint(staker, shares, claimable);
        emit RewardClaimed(staker, claimable, false);
    }

    function availableEtherBalanceOf(address provider) public view returns (int256) {
        return int256(etherBalanceOf(provider) - slashingsOf(provider));
    }

    function etherBalanceOf(address provider) public view returns (uint256) {
        return _etherBalances[provider];
    }

    function updateEther(address provider, uint256 val) public onlyOperator {
        _etherBalances[provider] = val;
    }

    function slashingsOf(address provider) public view returns (uint256) {
        return _slashings[provider];
    }

    /**
        @dev Slash eth, returns remaining needs to be slashed
    */
    function _slashETH(address provider, uint256 amount) private returns (uint256 remaining) {

        uint256 available = availableEtherBalanceOf(provider) > 0 ? uint256(availableEtherBalanceOf(provider)) : 0;

        uint256 toBeSlashed = amount.min(available);
        if (toBeSlashed == 0) return amount;

        _slashings[provider] = _slashings[provider].add(toBeSlashed);
        remaining = amount.sub(toBeSlashed);

        emit ProviderSlashedEth(provider, toBeSlashed);
    }

    function updateAETHContract(address payable tokenContract) external onlyOwner {
        _aethContract = IAETH(tokenContract);
    }

    function updateFETHContract(address payable tokenContract) external onlyOwner {
        _fethContract = IFETH(tokenContract);
    }

    function updateConfigContract(address configContract) external onlyOwner {
        _configContract = IConfig(configContract);
    }

    function updateStakingContract(address stakingContract) external onlyOwner {
        _stakingContract = IStaking(stakingContract);
    }

    function changeOperator(address operator) public onlyOwner {
        _operator = operator;
    }

    function depositContractAddress() public view returns (address) {
        return _depositContract;
    }

    function updateFETHRewards(uint256 _mintBase) external {
        require(msg.sender == address(_fethContract), "Not allowed");
        _fethMintBase = _mintBase;
    }

    function mintBase() external view returns(uint256) {
        return _fethMintBase;
    }

    function poolCount() public view returns (uint256) {
        return _totalStakes.div(32 ether);
    }

    function pendingStakesOf(address staker) public view returns (uint256) {
        return _pendingUserStakes[staker];
    }

    function pendingEtherBalanceOf(address provider) public view returns (uint256) {
        return _pendingEtherBalances[provider];
    }

    function updateStakers(address[] memory addrs, uint256[] memory feth0, uint256[] memory feth1, uint256[] memory aeth) public onlyOwner {
        require(addrs.length == feth0.length && feth0.length == feth1.length && aeth.length == feth0.length, "lengths not equal");
        for(uint256 i = 0; i < feth0.length; i++) {
            address staker = addrs[i];
            _fETHRewards[staker][0] = feth0[i];
            _fETHRewards[staker][1] = feth1[i];
            _aETHRewards[staker] = aeth[i];
        }
    }

    function unstake() public whenNotPaused("unstake") payable unlocked(msg.sender) notExitRecently(msg.sender) {
        uint256 pendingStakes = pendingStakesOf(msg.sender);

        require(pendingStakes > 0, "No pending stakes");

        _pendingUserStakes[msg.sender] = 0;
        _pendingEtherBalances[msg.sender] = 0;

        require(msg.sender.send(pendingStakes), "could not send ethers");

        emit StakeRemoved(msg.sender, pendingStakes);
    }

    uint256[50] private __gap;

    uint256 private _lastPendingStakerPointer;

    IConfig private _configContract;

    mapping(address => uint256) private _pendingEtherBalances;

    address private _operator;

    mapping (address => uint256[2]) private _fETHRewards;
    mapping (address => uint256) private _aETHRewards;

    IFETH private _fethContract;

    uint256 private _fethMintBase;
}

