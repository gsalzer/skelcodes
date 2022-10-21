/**
* @dev Xplosive Ethereum RewardsDistributionRecipient *Vetted* by COM Community
* @author Sparkle Loyalty Team ♥♥♥ SPRKL
*/


pragma solidity ^0.5.16;

contract RewardsDistributionRecipient {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) external;
    
    function updateRewardAmount(uint256 newRate) external;
    
    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }
}
