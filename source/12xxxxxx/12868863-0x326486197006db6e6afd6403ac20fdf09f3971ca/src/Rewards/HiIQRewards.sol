// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

// Distributes IQ protocol yield based on the claimer's hiIQ balance
// V3: Yield will now not accrue for unlocked hiIQ

// Originally inspired by Synthetixio, but heavily modified by the Frax team (hiIQ portion) & EP Team
// https://raw.githubusercontent.com/Synthetixio/synthetix/develop/contracts/StakingYield.sol

import "./TransferHelper.sol";
import "../Lock/IhiIQ.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract HiIQRewards is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    /* ========== STATE VARIABLES ========== */

    // Instances
    IhiIQ private hiIQ;
    ERC20 public emittedToken;

    // Addresses
    address public emitted_token_address;

    // Constant for price precision
    uint256 private constant PRICE_PRECISION = 1e6;

    // Yield and period related
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public yieldRate;
    uint256 public yieldDuration = 604800; // 7 * 86400  (7 days)

    // Yield tracking
    uint256 public yieldPerHiIQStored = 0;
    mapping(address => uint256) public userYieldPerTokenPaid;
    mapping(address => uint256) public yields;

    // hiIQ tracking
    uint256 public totalHiIQParticipating = 0;
    uint256 public totalHiIQSupplyStored = 0;
    mapping(address => bool) public userIsInitialized;
    mapping(address => uint256) public userHiIQCheckpointed;

    // Greylists
    mapping(address => bool) public greylist;

    // Admin booleans for emergencies
    bool public yieldCollectionPaused = false; // For emergencies

    struct LockedBalance {
        int128 amount;
        uint256 end;
    }

    /* ========== MODIFIERS ========== */

    modifier notYieldCollectionPaused() {
        require(yieldCollectionPaused == false, "Yield collection is paused");
        _;
    }

    modifier checkpointUser(address account) {
        _checkpointUser(account);
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _emittedToken, address _hiIQ_address) {
        emitted_token_address = _emittedToken;
        emittedToken = ERC20(_emittedToken);

        hiIQ = IhiIQ(_hiIQ_address);
        lastUpdateTime = block.timestamp;

        // 1 IQ a day at initialization
        yieldRate = (uint256(365e18)).div(365 * 86400);
    }

    /* ========== VIEWS ========== */

    function fractionParticipating() external view returns (uint256) {
        return totalHiIQParticipating.mul(PRICE_PRECISION).div(totalHiIQSupplyStored);
    }

    // Only positions with locked hiIQ can accrue yield. Otherwise, expired-locked hiIQ
    // is de-facto rewards for IQ.
    function eligibleCurrentHiIQ(address account) public view returns (uint256) {
        uint256 curr_hiiq_bal = hiIQ.balanceOf(account);
        IhiIQ.LockedBalance memory curr_locked_bal_pack = hiIQ.locked(account);

        // Only unexpired hiIQ should be eligible
        if (int256(curr_locked_bal_pack.amount) == int256(curr_hiiq_bal)) {
            return 0;
        } else {
            return curr_hiiq_bal;
        }
    }

    function lastTimeYieldApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function yieldPerHiIQ() public view returns (uint256) {
        if (totalHiIQSupplyStored == 0) {
            return yieldPerHiIQStored;
        } else {
            return (
                yieldPerHiIQStored.add(
                    lastTimeYieldApplicable().sub(lastUpdateTime).mul(yieldRate).mul(1e18).div(totalHiIQSupplyStored)
                )
            );
        }
    }

    function earned(address account) public view returns (uint256) {
        // Uninitialized users should not earn anything yet
        if (!userIsInitialized[account]) return 0;

        uint256 yield0 = yieldPerHiIQ();

        // Get the old and the new hiIQ balances
        uint256 old_hiiq_balance = userHiIQCheckpointed[account];
        uint256 new_hiiq_balance = eligibleCurrentHiIQ(account);

        // Analogous to midpoint Riemann sum
        uint256 midpoint_hiiq_balance = ((new_hiiq_balance).add(old_hiiq_balance)).div(2);

        return (midpoint_hiiq_balance.mul(yield0.sub(userYieldPerTokenPaid[account])).div(1e18).add(yields[account]));
    }

    function getYieldForDuration() external view returns (uint256) {
        return (yieldRate.mul(yieldDuration));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _checkpointUser(address account) internal {
        // Need to retro-adjust some things if the period hasn't been renewed, then start a new one
        sync();

        // Calculate the earnings first
        _syncEarned(account);

        // Get the old and the new hiIQ balances
        uint256 old_hiiq_balance = userHiIQCheckpointed[account];
        uint256 new_hiiq_balance = eligibleCurrentHiIQ(account);

        // Update the user's stored hiIQ balance
        userHiIQCheckpointed[account] = new_hiiq_balance;

        // Update the total amount participating
        if (new_hiiq_balance >= old_hiiq_balance) {
            uint256 weight_diff = new_hiiq_balance.sub(old_hiiq_balance);
            totalHiIQParticipating = totalHiIQParticipating.add(weight_diff);
        } else {
            uint256 weight_diff = old_hiiq_balance.sub(new_hiiq_balance);
            totalHiIQParticipating = totalHiIQParticipating.sub(weight_diff);
        }

        // Mark the user as initialized
        if (!userIsInitialized[account]) userIsInitialized[account] = true;
    }

    function _syncEarned(address account) internal {
        if (account != address(0)) {
            uint256 earned0 = earned(account);
            yields[account] = earned0;
            userYieldPerTokenPaid[account] = yieldPerHiIQStored;
        }
    }

    // Checkpoints the user
    function checkpoint() external {
        _checkpointUser(msg.sender);
    }

    function getYield()
        external
        nonReentrant
        notYieldCollectionPaused
        checkpointUser(msg.sender)
        returns (uint256 yield0)
    {
        require(greylist[msg.sender] == false, "Address has been greylisted");

        yield0 = yields[msg.sender];
        if (yield0 > 0) {
            yields[msg.sender] = 0;
            TransferHelper.safeTransfer(emitted_token_address, msg.sender, yield0);
            emit YieldCollected(msg.sender, yield0, emitted_token_address);
        }
    }

    // If the period expired, renew it
    function retroCatchUp() internal {
        // Failsafe check
        require(block.timestamp > periodFinish, "Period has not expired yet!");

        // Ensure the provided yield amount is not more than the balance in the contract.
        // This keeps the yield rate in the right range, preventing overflows due to
        // very high values of yieldRate in the earned and yieldPerToken functions;
        // Yield + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 num_periods_elapsed = uint256(block.timestamp.sub(periodFinish)) / yieldDuration;
        // Floor division to the nearest period
        uint256 balance0 = emittedToken.balanceOf(address(this));
        require(
            yieldRate.mul(yieldDuration).mul(num_periods_elapsed + 1) <= balance0,
            "Not enough emittedToken available for yield distribution!"
        );

        periodFinish = periodFinish.add((num_periods_elapsed.add(1)).mul(yieldDuration));

        uint256 yield0 = yieldPerHiIQ();
        yieldPerHiIQStored = yield0;
        lastUpdateTime = lastTimeYieldApplicable();

        emit YieldPeriodRenewed(emitted_token_address, yieldRate);
    }

    function sync() public {
        // Update the total hiIQ supply
        totalHiIQSupplyStored = hiIQ.totalSupply();

        if (block.timestamp > periodFinish) {
            retroCatchUp();
        } else {
            uint256 yield0 = yieldPerHiIQ();
            yieldPerHiIQStored = yield0;
            lastUpdateTime = lastTimeYieldApplicable();
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // Added to support recovering LP Yield and other mistaken tokens from other systems to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        // Only the owner address can ever receive the recovery withdrawal
        TransferHelper.safeTransfer(tokenAddress, owner(), tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    function setYieldDuration(uint256 _yieldDuration) external onlyOwner {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Previous yield period must be complete before changing the duration for the new period"
        );
        yieldDuration = _yieldDuration;
        emit YieldDurationUpdated(yieldDuration);
    }

    function initializeDefault() external onlyOwner {
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(yieldDuration);
        totalHiIQSupplyStored = hiIQ.totalSupply();
        emit DefaultInitialization();
    }

    function greylistAddress(address _address) external onlyOwner {
        greylist[_address] = !(greylist[_address]);
    }

    function setPauses(bool _yieldCollectionPaused) external onlyOwner {
        yieldCollectionPaused = _yieldCollectionPaused;
    }

    function setYieldRate(uint256 _new_rate0, bool sync_too) external onlyOwner {
        yieldRate = _new_rate0;

        if (sync_too) {
            sync();
        }
    }

    /* ========== EVENTS ========== */

    event YieldCollected(address indexed user, uint256 yield, address token_address);
    event YieldDurationUpdated(uint256 newDuration);
    event RecoveredERC20(address token, uint256 amount);
    event YieldPeriodRenewed(address token, uint256 yieldRate);
    event DefaultInitialization();
}

