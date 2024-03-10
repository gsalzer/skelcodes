pragma solidity ^0.6.0;
/**
 *Submitted for verification at Etherscan.io on 2020-07-17
 */

/*
   ____            __   __        __   _
  / __/__ __ ___  / /_ / /  ___  / /_ (_)__ __
 _\ \ / // // _ \/ __// _ \/ -_)/ __// / \ \ /
/___/ \_, //_//_/\__//_//_/\__/ \__//_/ /_\_\
     /___/

* Synthetix: BASISCASHRewards.sol
*
* Docs: https://docs.synthetix.io/
*
*
* MIT License
* ===========
*
* Copyright (c) 2020 Synthetix
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
*/

// File: @openzeppelin/contracts/math/Math.sol

import './Math.sol';

// File: @openzeppelin/contracts/math/SafeMath.sol

import './SafeMath.sol';

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

import './IERC20.sol';

// File: @openzeppelin/contracts/utils/Address.sol

import './Address.sol';

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol

import './SafeERC20.sol';

// File: contracts/IRewardDistributionRecipient.sol

import './IRewardDistributionRecipient.sol';

import './LPTokenWrapper.sol';

import './IInvitation.sol';

contract DAIiBACLPTokenSharePool is
    LPTokenWrapper
{
    IERC20 public ibasisShare;
    IInvitation public invitation;
    uint256 public constant DURATION = 30 days;

    uint256 public initreward = 77453 * 10**18; 
    uint256 public starttime; // starttime TBD
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(
        address ibasisShare_,
        address lptoken_,
        uint256 starttime_,
        address invitation_
    ) public {
        ibasisShare = IERC20(ibasisShare_);
        lpt = IERC20(lptoken_);
        starttime = starttime_;
        rewardRate = initreward.div(DURATION);
        lastUpdateTime = starttime;
        periodFinish = starttime.add(DURATION);
        invitation = IInvitation(invitation_);
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
    function stake(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkhalve
        checkStart
    {
        require(amount > 0, 'Cannot stake 0');
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        updateReward(msg.sender)
        checkhalve
        checkStart
    {
        require(amount > 0, 'Cannot withdraw 0');
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkhalve checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            ibasisShare.safeTransfer(msg.sender, reward); //100%
            ibasisShare.safeTransfer(team, reward.mul(12).div(100)); //12%
            ibasisShare.safeTransfer(government, reward.mul(8).div(100)); //8%
            ibasisShare.safeTransfer(insurance , reward.mul(5).div(100)); //5%
            address inviter = invitation.getInviter(msg.sender);
            address inviter2 = invitation.getInviter(inviter);
            if(inviter!=address(0) && inviter != address(1)) {
                ibasisShare.safeTransfer(inviter,reward.mul(2).div(100));
                emit InvitationReward(inviter, 1, reward.mul(2).div(100));
            } 
            if(inviter2!=address(0) && inviter2 != address(1)) {
                ibasisShare.safeTransfer(inviter2,reward.mul(1).div(100));
                emit InvitationReward(inviter2, 2, reward.mul(1).div(100));
            }
            emit RewardPaid(msg.sender, reward);
        }
    }

    modifier checkhalve() {
        if (block.timestamp >= periodFinish) {
            initreward = initreward.mul(75).div(100);

            rewardRate = initreward.div(DURATION);
            periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(initreward);
        }
        _;
    }

    modifier checkStart() {
        require(block.timestamp >= starttime, 'not start');
        _;
    }

   
}

