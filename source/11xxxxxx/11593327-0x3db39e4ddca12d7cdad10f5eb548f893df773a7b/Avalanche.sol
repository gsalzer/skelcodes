// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import { IERC20 } from './IERC20.sol';
import { AvalancheBase } from "./AvalancheBase.sol";
import { IAvalanche } from "./IAvalanche.sol";
import { IFROST } from "./IFROST.sol";
import { ILoyalty } from "./ILoyalty.sol";
import { ISlopes } from "./ISlopes.sol";

contract Avalanche is IAvalanche, AvalancheBase {
    event Activated(address indexed user);
    event Distribution(address indexed user, uint256 totalFrostRewards, uint256 payoutPerDay);
    event Claim(address indexed user, uint256 frostAmount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event FrostRewardAdded(address indexed user, uint256 frostReward);
    event EthRewardAdded(address indexed user, uint256 ethReward);

    uint256 public constant PAYOUT_INTERVAL = 24 hours; // How often the payouts occur
    uint256 public constant TOTAL_PAYOUTS = 20; // How many payouts per distribution cycle
    
    uint256 public nextEpochFrostReward; // accumulated frost for next distribution cycle
    uint256 public epochFrostReward; // current epoch rewards
    uint256 public epochFrostRewardPerDay; // 5% per day, 20 days
    uint256 public unstakingFee; // The unstaking fee that is used to increase locked liquidity and reward Avalanche stakers (1 = 0.1%). Defaults to 10%
    uint256 public buybackAmount; // The amount of FROST-ETH LP tokens kept by the unstaking fee that will be converted to FROST and distributed to stakers (1 = 0.1%). Defaults to 50%

    bool public override active; // Becomes true once the 'activate' function called

    uint256 public startTime; // When the first payout can be processed (timestamp). It will be 24 hours after the Avalanche contract is activated
    uint256 public lastPayout; // When the last payout was processed (timestamp)
    uint256 public lastReward; // timestamp when last frost reward was minted
    uint256 public totalPendingFrost; // The total amount of pending FROST available for stakers to claim
    uint256 public accFrostPerShare; // Accumulated FROST per share, times 1e12.
    uint256 public totalStaked; // The total amount of FROST-ETH LP tokens staked in the contract
    uint256 public totalShares; // The total amount of pool shares
    uint256 public weight; // pool weight 

    modifier AvalancheActive {
        require(active, "Avalanche is not active");
        _;
    }

    modifier SlopesActive {
        require(ISlopes(slopesAddress()).active(), "Slopes are not active");
        _;
    }

    constructor(address addressRegistry) 
        public 
        AvalancheBase(addressRegistry)
    {
        unstakingFee = 100;
        buybackAmount = 500;
        weight = 5;
    }

    // activate the avalanche distribution phase
    //  signified avalanche is open on first call and calcs
    //  all necessary rewards vars
    function activate() 
        external
        override
        OnlyFROST
    {
        if (!active) {
            active = true;
        }

        // The first payout can be processed 24 hours after activation
        startTime = block.timestamp + getDistributionPayoutInterval(); 
        lastPayout = startTime;
        epochFrostReward = nextEpochFrostReward;
        epochFrostRewardPerDay = epochFrostReward.div(getTotalDistributionPayouts());
        nextEpochFrostReward = 0;
    }

    // The _transfer function in the FROST contract calls this to let the Avalanche contract know that it received the specified amount of FROST to be distributed 
    function addFrostReward(address _from, uint256 _amount) 
        external
        override
        // NonZeroAmount(_amount)
        SlopesActive
        OnlyFROST
    {
        // if max supply is hit, distribute directly to pool
        // else always add reward to next epoch rewards.
        if (IFROST(frostAddress()).maxSupplyHit()) {
            totalPendingFrost = totalPendingFrost.add(_amount);
            accFrostPerShare = accFrostPerShare.add(_amount.mul(1e12).div(totalShares));
        } else {
            nextEpochFrostReward = nextEpochFrostReward.add(_amount);
        }

        emit FrostRewardAdded(_from, _amount);
    }

    receive() external payable {
        addEthReward();
    }

    // Allows external sources to add ETH to the contract which is used to buy and then distribute FROST to stakers
    function addEthReward() 
        public 
        payable
        SlopesActive
    {
        uint256 ethBalance = address(this).balance;
        require(ethBalance > 0, "Must have eth to swap");
        _swapExactETHForTokens(address(this).balance, frostAddress());

        // The _transfer function in the FROST contract calls the Avalanche contract's updateOwdrReward function 
        // so we don't need to update the balances after buying the PWRD token
        emit EthRewardAdded(msg.sender, msg.value);
    }

    function _updatePool() 
        internal 
        AvalancheActive
    {
        if (IFROST(frostAddress()).accumulating()) {
            _processAccumulationPayouts();
        } else {
            _processDistributionPayouts();
        }
    }

    // handles updating the pool during accumulation phases
    function _processAccumulationPayouts() internal {
        if (block.timestamp <= lastReward) {
            return;
        }

        if (totalStaked == 0) {
            lastReward = block.timestamp;
            return;
        }

        // Calculate the current FROST rewards for a specific pool
        //  using fixed APR formula and Uniswap price
        uint256 tokenPrice = _getLpTokenPrice(frostPoolAddress());
        uint256 frostReward = _calculatePendingRewards(
            lastReward,
            totalShares,
            tokenPrice,
            weight
        );

        // if we hit the max supply here, ensure no overflow 
        //  epoch will be incremented from the token
        address frostAddress = frostAddress();
        uint256 frostTotalSupply = IERC20(frostAddress).totalSupply();
        if (frostTotalSupply.add(frostReward) >= IFROST(frostAddress).currentMaxSupply()) {
            frostReward = IFROST(frostAddress).currentMaxSupply().sub(frostTotalSupply);
        }

        if (frostReward > 0) {
            IFROST(frostAddress).mint(address(this), frostReward);
            accFrostPerShare = accFrostPerShare.add(frostReward.mul(1e12).div(totalShares));
            lastReward = block.timestamp;
        }
    }

    // Handles paying out the fixed distribution payouts over 20 days
    // rewards directly added to accFrostPerShare at max supply hit, becomes a direct calculation
    function _processDistributionPayouts() internal {
        if (!active || block.timestamp < startTime 
            || block.timestamp <= lastReward
            || IFROST(frostAddress()).maxSupplyHit() 
            || epochFrostReward == 0 || totalStaked == 0) 
        {
            return;
        }

        // How many days since last payout?
        uint256 daysSinceLastPayout = (block.timestamp - lastPayout) / getDistributionPayoutInterval();

        // If less than 1, don't do anything
        if (daysSinceLastPayout == 0) {
            return;
        }

        // Work out how many payouts have been missed
        uint256 payoutNumber = payoutNumber();
        uint256 previousPayoutNumber = payoutNumber - daysSinceLastPayout;

        // Calculate how much additional reward we have to hand out
        uint256 frostReward = rewardAtPayout(payoutNumber) - rewardAtPayout(previousPayoutNumber);
        if (frostReward > epochFrostReward) {
            frostReward = epochFrostReward;
        }
        epochFrostReward = epochFrostReward.sub(frostReward);

        // Payout the frostReward to the stakers
        totalPendingFrost = totalPendingFrost.add(frostReward);
        accFrostPerShare = accFrostPerShare.add(frostReward.mul(1e12).div(totalShares));

        // Update lastPayout time
        lastPayout += (daysSinceLastPayout * getDistributionPayoutInterval());
        lastReward = block.timestamp;

        if (payoutNumber >= getTotalDistributionPayouts()) {
            IFROST(frostAddress()).updateEpoch(IFROST(frostAddress()).currentEpoch() + 1, 0);
        }
    }

    // Claim earned FROST
    function claim()
        external
        override
    {        
        _updatePool();
        _claim(msg.sender);
    }

    function claimFor(address _user)
        external
        override
        OnlyLoyalty
    {
        _updatePool();
        _claim(_user);
    }

    function _claim(address _user)
        internal
        AvalancheActive
    {
        UserInfo storage user = userInfo[_user];
        if (user.staked > 0) {
            uint256 pendingFrostReward = user.shares.mul(accFrostPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingFrostReward > 0) {
                totalPendingFrost = totalPendingFrost.sub(pendingFrostReward);
                user.claimed += pendingFrostReward;
                user.rewardDebt = user.shares.mul(accFrostPerShare).div(1e12);

                // update user/pool shares
                uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, user.staked);
                if (shares > user.shares) {
                    totalShares = totalShares.add(shares.sub(user.shares));
                } else if (shares < user.shares) {
                    totalShares = totalShares.sub(user.shares.sub(shares));
                }
                user.shares = shares;

                _safeTokenTransfer(
                    frostAddress(),
                    _user,
                    pendingFrostReward
                );

                emit Claim(_user, pendingFrostReward);
            }
        }
    }

     // Stake FROST-ETH LP tokens
    function deposit(uint256 _amount) 
        external
        override
    {
        _deposit(msg.sender, msg.sender, _amount);
    }

    // stake for another user, used to migrate to this pool
    function depositFor(address _from, address _user, uint256 _amount)
        external
        override
        OnlySlopes
    {
        _deposit(_from, _user, _amount);
    }

    // Stake FROST-ETH LP tokens for address
    function _deposit(address _from, address _user, uint256 _amount) 
        internal 
        AvalancheActive
        NonZeroAmount(_amount)
    {
        IERC20(frostPoolAddress()).safeTransferFrom(_from, address(this), _amount);

        _updatePool();

        _claim(_user);


        UserInfo storage user = userInfo[_user];

        uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, _amount);
        totalShares = totalShares.add(shares);
        user.shares = user.shares.add(shares);

        totalStaked = totalStaked.add(_amount);
        user.staked = user.staked.add(_amount);
        user.rewardDebt = user.shares.mul(accFrostPerShare).div(1e12);

        emit Deposit(_user, _amount);
    }

    // Unstake and withdraw FROST-ETH LP tokens and any pending FROST rewards. 
    // There is a 10% unstaking fee, meaning the user will only receive 90% of their LP tokens back.
    
    // For the LP tokens kept by the unstaking fee, a % will get locked forever in the FROST contract, and the rest will get converted to FROST and distributed to stakers.
    //TODO -> change ratio to 75% convertion to rewards
    function withdraw(uint256 _amount)
        external
        override
    {
        _withdraw(_msgSender(), _amount);
    }

    function _withdraw(address _user, uint256 _amount) 
        internal
        AvalancheActive
        NonZeroAmount(_amount)
        HasStakedBalance(_user)
        HasWithdrawableBalance(_user, _amount)
    {
        _updatePool();

        UserInfo storage user = userInfo[_user];
        
        uint256 unstakingFeeAmount = _amount.mul(unstakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(unstakingFeeAmount);

        // Some of the LP tokens kept by the unstaking fee will be locked forever in the FROST contract, 
        // the rest  will be converted to FROST and distributed to stakers
        uint256 lpTokensToConvertToFrost = unstakingFeeAmount.mul(buybackAmount).div(1000);
        uint256 lpTokensToLock = unstakingFeeAmount.sub(lpTokensToConvertToFrost);

        // Remove the liquidity from the Uniswap FROST-ETH pool and buy FROST with the ETH received
        // The _transfer function in the FROST.sol contract automatically calls avalanche.addFrostRewards()
        if (lpTokensToConvertToFrost > 0) {
            _removeLiquidityETH(
                lpTokensToConvertToFrost,
                frostPoolAddress(),
                frostAddress()
            );
            addEthReward();
        }

        // Permanently lock the LP tokens in the FROST contract
        if (lpTokensToLock > 0) {
            IERC20(frostPoolAddress()).safeTransfer(vaultAddress(), lpTokensToLock);
        }

        // Claim any pending FROST
        _claim(_user);

        uint256 shares = ILoyalty(loyaltyAddress()).getTotalShares(_user, _amount);
        totalShares = totalShares.sub(shares);
        user.shares = user.shares.sub(shares);

        totalStaked = totalStaked.sub(_amount);
        user.staked = user.staked.sub(_amount);
        user.rewardDebt = user.shares.mul(accFrostPerShare).div(1e12); // update reward debt after balance change

        IERC20(frostPoolAddress()).safeTransfer(_user, remainingUserAmount);
        emit Withdraw(_user, remainingUserAmount);
    }

    function payoutNumber() 
        public
        override
        view 
        returns (uint256) 
    {
        if (block.timestamp < startTime) {
            return 0;
        }

        return (block.timestamp - startTime).div(getDistributionPayoutInterval());
    }

    function timeUntilNextPayout()
        external
        override
        view 
        returns (uint256) 
    {
        if (epochFrostReward == 0) {
            return 0;
        } else {
            uint256 payout = payoutNumber();
            uint256 nextPayout = startTime.add((payout + 1).mul(getDistributionPayoutInterval()));
            return nextPayout - block.timestamp;
        }
    }

    function rewardAtPayout(uint256 _payoutNumber) 
        public
        override
        view 
        returns (uint256) 
    {
        if (_payoutNumber == 0) {
            return 0;
        } else {
            return epochFrostRewardPerDay * _payoutNumber;
        }
    }

    function getTotalDistributionPayouts() public virtual pure returns (uint256) {
        return TOTAL_PAYOUTS;
    }

    function getDistributionPayoutInterval() public virtual pure returns (uint256) {
        return PAYOUT_INTERVAL;
    }

    function updatePool()
        external
        HasPatrol("ADMIN")
    {
        _updatePool();
    }

    // Sets the unstaking fee. Can't be higher than 50%.
    // _convertToFrostAmount is the % of the LP tokens from the unstaking fee that will be converted to FROST and distributed to stakers.
    // unstakingFee - unstakingFeeConvertToFrostAmount = The % of the LP tokens from the unstaking fee that will be permanently locked in the FROST contract
    function setUnstakingFee(uint256 _unstakingFee, uint256 _buybackAmount) 
        external
        //override
        HasPatrol("ADMIN") 
    {
        require(_unstakingFee <= 500, "over 50%");
        require(_buybackAmount <= 1000, "bad amount");
        unstakingFee = _unstakingFee;
        buybackAmount = _buybackAmount;
    }

    // Function to recover ERC20 tokens accidentally sent to the contract.
    // FROST and FROST-ETH LP tokens (the only 2 ERC2O's that should be in this contract) can't be withdrawn this way.
    function recoverERC20(address _tokenAddress) 
        external
        //override
        HasPatrol("ADMIN") 
    {
        require(_tokenAddress != frostAddress() && _tokenAddress != frostPoolAddress());
        IERC20 token = IERC20(_tokenAddress);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.safeTransfer(msg.sender, tokenBalance);
    }

     function getAvalancheStats(address _user) 
        external 
        view 
        returns (bool _active, bool _accumulating, uint256[20] memory _stats)
    {
        _active = active;
        _accumulating = IFROST(frostAddress()).accumulating();
        
        UserInfo storage user = userInfo[_user];

        _stats[0] = weight * IFROST(frostAddress()).currentBaseRate();
        _stats[1] = lastReward;
        _stats[2] = totalStaked;
        _stats[3] = totalShares;
        _stats[4] = accFrostPerShare;
        _stats[5] = _getTokenPrice(frostAddress(), frostPoolAddress());
        _stats[6] = _getLpTokenPrice(frostPoolAddress());

        _stats[7] = nextEpochFrostReward;
        _stats[8] = epochFrostReward;
        _stats[9] = epochFrostRewardPerDay;
        _stats[10] = startTime;
        _stats[11] = lastPayout; 
        _stats[12] = payoutNumber();
        _stats[13] = unstakingFee;

        _stats[14] = IERC20(frostPoolAddress()).balanceOf(_user);
        _stats[15] = IERC20(frostPoolAddress()).allowance(_user, address(this));
        _stats[16] = user.staked;
        _stats[17] = user.shares;
        _stats[18] = user.shares.mul(accFrostPerShare).div(1e12).sub(user.rewardDebt); // pending rewards
        _stats[19] = user.claimed;
    }
}
