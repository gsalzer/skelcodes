/**
* @dev Sparkle Swap StakingRewardsFactory 
* @author Sparkle Loyalty Team ♥♥♥ SPRKL
*/

pragma solidity ^0.5.16;

import '../../openzeppelin-contracts/contracts/token/ERC20/IERC20.sol';
import '../../openzeppelin-contracts/contracts/ownership/Ownable.sol';

import './StakingRewards.sol';

contract StakingRewardsFactory is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // immutables
    address public rewardsToken;
    uint256 public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint256 rewardAmount;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        address _rewardsToken,
        uint256 _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

   
    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingToken, address payable collectionAddress, uint rewardAmount) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), 'StakingRewardsFactory::deploy: already deployed');

        info.stakingRewards = address(new StakingRewards(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken, collectionAddress));
        info.rewardAmount = rewardAmount;
        stakingTokens.push(stakingToken);
    }
    
    
     // Withdraw tokens in case functions exceed gas cost unipoop -_-
    function withdrawRewardToken (uint256 amount) public onlyOwner returns (uint256) {
    address OwnerAddress = owner();  
    if (OwnerAddress == msg.sender)    
     IERC20(rewardsToken).transfer(OwnerAddress, amount);
     return amount;
    }
    
    
    
    // Send additional tokens for new rate + Update rate for individual tokens 
    function updateRewardAmount(address stakingToken, uint256 newRate) public onlyOwner {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyRewardAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0) {
            uint256 rewardAmount = info.rewardAmount.add(newRate);
            info.rewardAmount = 0;
            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, newRate),
                'StakingRewardsFactory::notifyRewardAmount: transfer failed'
            );
            
            StakingRewards(info.stakingRewards).updateRewardAmount(rewardAmount);
        }
    }
    


    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyRewardAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0) {
            uint256 rewardAmount = info.rewardAmount;
            info.rewardAmount = 0;

            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
                'StakingRewardsFactory::notifyRewardAmount: transfer failed'
            );
            StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
        }
    }
    
     ///// permissionless function

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public {
        require(stakingTokens.length > 0, 'StakingRewardsFactory::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }
}
