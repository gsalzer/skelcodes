// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import './StakingRewards.sol';

import './interfaces/IStakedEthix.sol';
import './interfaces/ITransferHook.sol';

import '../../../reserve/IReserve.sol';

import './lib/EthixERC20Snapshot.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/Initializable.sol';

/**
 * @title StakedToken
 * @notice Contract to stake Ethix token, tokenize the position and get rewards, inheriting from a distribution manager contract
 * @author Aave / Ethichub
 **/
contract StakedToken is Initializable, IStakedEthix, EthixERC20Snapshot, StakingRewards {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    IERC20Upgradeable public STAKED_TOKEN;
    uint256 public COOLDOWN_SECONDS;

    /// @notice Seconds available to redeem once the cooldown period is fullfilled
    uint256 public UNSTAKE_WINDOW;

    /// @notice IReserve to pull from the rewards, needs to have this contract as WITHDRAW role
    IReserve public REWARDS_VAULT;

    mapping(address => uint256) public stakerRewardsToClaim;
    mapping(address => uint256) public stakersCooldowns;

    event Staked(address indexed from, address indexed onBehalfOf, uint256 amount);
    event Redeem(address indexed from, address indexed to, uint256 amount);

    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed from, address indexed to, uint256 amount);

    event Cooldown(address indexed user);

    function __StakedToken_init(
        string memory name,
        string memory symbol,
        uint8 decimals,
        ITransferHook ethixGovernance,
        IERC20Upgradeable stakedToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        IReserve rewardsVault,
        address emissionManager,
        uint128 distributionDuration
    ) internal initializer {
        __EthixERC20Snapshot_init(name, symbol);
        _setupDecimals(decimals);
        _setEthixGovernance(ethixGovernance);
        __StakingRewards_init(emissionManager, distributionDuration);
        STAKED_TOKEN = stakedToken;
        COOLDOWN_SECONDS = cooldownSeconds;
        UNSTAKE_WINDOW = unstakeWindow;
        REWARDS_VAULT = rewardsVault;
    }

    function stake(address onBehalfOf, uint256 amount) external override {
        require(amount != 0, 'INVALID_ZERO_AMOUNT');
        uint256 balanceOfUser = balanceOf(onBehalfOf);

        uint256 accruedRewards =
            _updateUserAssetInternal(onBehalfOf, address(this), balanceOfUser, totalSupply());
        if (accruedRewards != 0) {
            emit RewardsAccrued(onBehalfOf, accruedRewards);
            stakerRewardsToClaim[onBehalfOf] = stakerRewardsToClaim[onBehalfOf].add(accruedRewards);
        }

        stakersCooldowns[onBehalfOf] = getNextCooldownTimestamp(
            0,
            amount,
            onBehalfOf,
            balanceOfUser
        );

        _mint(onBehalfOf, amount);
        IERC20Upgradeable(STAKED_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, onBehalfOf, amount);
    }

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param to Address to redeem to
     * @param amount Amount to redeem
     **/
    function redeem(address to, uint256 amount) external override {
        require(amount != 0, 'INVALID_ZERO_AMOUNT');
        //solium-disable-next-line
        uint256 cooldownStartTimestamp = stakersCooldowns[msg.sender];
        require(
            block.timestamp > cooldownStartTimestamp.add(COOLDOWN_SECONDS),
            'INSUFFICIENT_COOLDOWN'
        );
        require(
            block.timestamp.sub(cooldownStartTimestamp.add(COOLDOWN_SECONDS)) <= UNSTAKE_WINDOW,
            'UNSTAKE_WINDOW_FINISHED'
        );
        uint256 balanceOfMessageSender = balanceOf(msg.sender);

        uint256 amountToRedeem =
            (amount > balanceOfMessageSender) ? balanceOfMessageSender : amount;

        _updateCurrentUnclaimedRewards(msg.sender, balanceOfMessageSender, true);

        _burn(msg.sender, amountToRedeem);

        if (balanceOfMessageSender.sub(amountToRedeem) == 0) {
            stakersCooldowns[msg.sender] = 0;
        }

        IERC20Upgradeable(STAKED_TOKEN).safeTransfer(to, amountToRedeem);

        emit Redeem(msg.sender, to, amountToRedeem);
    }

    /**
     * @dev Activates the cooldown period to unstake
     * - It can't be called if the user is not staking
     **/
    function cooldown() external override {
        require(balanceOf(msg.sender) != 0, 'INVALID_BALANCE_ON_COOLDOWN');
        //solium-disable-next-line
        stakersCooldowns[msg.sender] = block.timestamp;

        emit Cooldown(msg.sender);
    }

    /**
     * @dev Claims an `amount` from Rewards reserve to the address `to`
     * @param to Address to stake for
     * @param amount Amount to stake
     **/
    function claimRewards(address payable to, uint256 amount) external override {
        uint256 newTotalRewards =
            _updateCurrentUnclaimedRewards(msg.sender, balanceOf(msg.sender), false);
        uint256 amountToClaim = (amount == type(uint256).max) ? newTotalRewards : amount;

        stakerRewardsToClaim[msg.sender] = newTotalRewards.sub(amountToClaim, 'INVALID_AMOUNT');

        require(REWARDS_VAULT.transfer(to, amountToClaim), 'ERROR_TRANSFER_FROM_VAULT');

        emit RewardsClaimed(msg.sender, to, amountToClaim);
    }

    /**
     * @dev Internal ERC20 _transfer of the tokenized staked tokens
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param amount Amount to transfer
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balanceOfFrom = balanceOf(from);
        // Sender
        _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);

        // Recipient
        if (from != to) {
            uint256 balanceOfTo = balanceOf(to);
            _updateCurrentUnclaimedRewards(to, balanceOfTo, true);

            uint256 previousSenderCooldown = stakersCooldowns[from];
            stakersCooldowns[to] = getNextCooldownTimestamp(
                previousSenderCooldown,
                amount,
                to,
                balanceOfTo
            );
            // if cooldown was set and whole balance of sender was transferred - clear cooldown
            if (balanceOfFrom == amount && previousSenderCooldown != 0) {
                stakersCooldowns[from] = 0;
            }
        }

        super._transfer(from, to, amount);
    }

    /**
     * @dev Updates the user state related with his accrued rewards
     * @param user Address of the user
     * @param userBalance The current balance of the user
     * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
     * @return The unclaimed rewards that were added to the total accrued
     **/
    function _updateCurrentUnclaimedRewards(
        address user,
        uint256 userBalance,
        bool updateStorage
    ) internal returns (uint256) {
        uint256 accruedRewards =
            _updateUserAssetInternal(user, address(this), userBalance, totalSupply());
        uint256 unclaimedRewards = stakerRewardsToClaim[user].add(accruedRewards);

        if (accruedRewards != 0) {
            if (updateStorage) {
                stakerRewardsToClaim[user] = unclaimedRewards;
            }
            emit RewardsAccrued(user, accruedRewards);
        }

        return unclaimedRewards;
    }

    /**
     * @dev Calculates the how is gonna be a new cooldown timestamp depending on the sender/receiver situation
     *  - If the timestamp of the sender is "better" or the timestamp of the recipient is 0, we take the one of the recipient
     *  - Weighted average of from/to cooldown timestamps if:
     *    # The sender doesn't have the cooldown activated (timestamp 0).
     *    # The sender timestamp is expired
     *    # The sender has a "worse" timestamp
     *  - If the receiver's cooldown timestamp expired (too old), the next is 0
     * @param _fromCooldownTimestamp Cooldown timestamp of the sender
     * @param _amountToReceive Amount
     * @param _toAddress Address of the recipient
     * @param _toBalance Current balance of the receiver
     * @return The new cooldown timestamp
     **/
    function getNextCooldownTimestamp(
        uint256 _fromCooldownTimestamp,
        uint256 _amountToReceive,
        address _toAddress,
        uint256 _toBalance
    ) public returns (uint256) {
        uint256 toCooldownTimestamp = stakersCooldowns[_toAddress];
        if (toCooldownTimestamp == 0) {
            return 0;
        }

        uint256 minimalValidCooldownTimestamp =
            block.timestamp.sub(COOLDOWN_SECONDS).sub(UNSTAKE_WINDOW);

        if (minimalValidCooldownTimestamp > toCooldownTimestamp) {
            toCooldownTimestamp = 0;
        } else {
            uint256 fromCooldownTimestamp =
                (minimalValidCooldownTimestamp > _fromCooldownTimestamp)
                    ? block.timestamp
                    : _fromCooldownTimestamp;

            if (fromCooldownTimestamp < toCooldownTimestamp) {
                return toCooldownTimestamp;
            } else {
                toCooldownTimestamp = (
                    _amountToReceive.mul(fromCooldownTimestamp).add(
                        _toBalance.mul(toCooldownTimestamp)
                    )
                )
                    .div(_amountToReceive.add(_toBalance));
            }
        }
        stakersCooldowns[_toAddress] = toCooldownTimestamp;

        return toCooldownTimestamp;
    }

    /**
     * @dev Return the total rewards pending to claim by an staker
     * @param staker The staker address
     * @return The rewards
     */
    function getTotalRewardsBalance(address staker) external view returns (uint256) {
        DistributionTypes.UserStakeInput[] memory userStakeInputs =
            new DistributionTypes.UserStakeInput[](1);
        userStakeInputs[0] = DistributionTypes.UserStakeInput({
            underlyingAsset: address(this),
            stakedByUser: balanceOf(staker),
            totalStaked: totalSupply()
        });
        return stakerRewardsToClaim[staker].add(_getUnclaimedRewards(staker, userStakeInputs));
    }
}

