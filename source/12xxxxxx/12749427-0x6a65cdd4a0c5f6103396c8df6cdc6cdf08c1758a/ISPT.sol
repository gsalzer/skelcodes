pragma solidity ^0.7.0;

import "./IERC20.sol";

interface ISPT is IERC20 {
    
    function totalBurned() external view returns (uint256);
    function totalFromSpirits() external view returns (uint256);
    function totalFromAddons() external view returns (uint256);
    function totalAccumulatedSupply() external view returns (uint256);
    
    function accumulated(uint256 tokenIndex) external view returns (uint256);
    function totalAccumulated(uint256 tokenIndex, bool useRewardMultiplier) external view returns (uint256);
    function totalClaimed(uint256 tokenIndex) external view returns (uint256);
    
    function accumulatedNode(uint256 nodeId) external view returns (uint256);
    function totalAccumulatedNode(uint256 nodeId) external view returns (uint256);
    function lastClaimNode(uint256 nodeId) external view returns (uint256);
    function timeSinceLastClaimNode(uint256 nodeId) external view returns (uint256);
    function nodeEmissionMultiplier(uint256 nodeType) external view returns (uint256);
    function nodeEmissionRate(uint256 regTime) external view returns (uint256);
    function totalClaimedNode(uint256 nodeId) external view returns (uint256);
    function nodeEmissionEnds() external pure returns (uint256);
    function canClaimFromNode(uint256 nodeId) external view returns (bool);
    
    function totalAccumulatedDevFund() external view returns (uint256);
    function totalClaimableDevFund() external view returns (uint256);
    function totalClaimedDevFund() external view returns (uint256);
}
